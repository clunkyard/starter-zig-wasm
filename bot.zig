// A starter robot for rules v2, in Zig on WebAssembly ABI 4: it calls the
// robot core through the clunkyard.* imports in clunkyard.zig, next to this
// file. It sweeps a medium scan to find a robot, narrows the scan to hold it,
// leads it with shots whose power suits the range, fires only when the
// turret is on target and its aim is earned, keeps battery back for driving, looks again where it
// last saw one, follows a passive cue when it has nothing better and steps
// out of the storm.
//
// The trade-offs (the imports answer with the numbers the hello set):
//   scan     a narrow arc reaches further; a wide one finds robots nearby
//   power    heavy shots hit harder for less battery, but fly slowly
//   battery  shots and driving share it, and it refills slowly
//   turret   it turns at a limited rate; cy.gun_aim_now is where it points now
//   fuel     every import costs fuel, and so does every operator, so read
//            each fact once a turn and keep what you remember in place
// Bearing is earned: a scan contact's bearing is off by up to its
// bearing_error degrees (a fixed share of the arc), so a wide beam finds a
// robot and a narrow one aims at it. Contacts within 120 units are exact.
// A cue (cy.tracker_cue) says roughly where a robot is, within its
// bearing_error degrees: good for where to look, not where to shoot.
// Clunkyard WebAssembly ABI 4: the robot calls the core through imports
// from "clunkyard", declared in clunkyard.h. Export memory and, through
// CY_ROBOT(start, turn), clunkyard_start and clunkyard_turn. Each import
// returns a status (CY_OK 0, CY_NONE 1 for absent) and writes results
// through pointers; each costs fuel. In C each import is cy_<name>, as
// cy_sensors_nearest(&contact).
// match: match_mode match_ruleset match_control match_robots match_is_3d
//   match_tick_rate match_max_ticks robot_id robot_seed
// clock: clock_tick clock_seconds clock_remaining_ticks
// arena: arena_size arena_gravity arena_terrain_kind arena_ground_height
// me: me_health me_position me_velocity me_heading me_pitch me_roll
//   me_angular_velocity me_attitude me_grounded me_altitude
//   me_wall_contact me_applied me_hull_mounts me_to_mount me_from_mount
//   me_mount_toward
// battery: battery_charge battery_capacity battery_regen
//   battery_sustainable_drive battery_compute battery_drive_cost
// drive: drive_hover_lift drive_throttle drive_turn drive_pitch_turn
//   drive_thrust drive_strafe drive_lift drive_yaw_torque
//   drive_pitch_torque drive_roll_torque drive_brake drive_get_throttle
//   drive_get_turn drive_get_pitch_turn drive_get_thrust drive_get_strafe
//   drive_get_lift drive_get_yaw_torque drive_get_pitch_torque
//   drive_get_roll_torque drive_get_brake
// gun: gun_aim_now gun_cooldown_ticks gun_spread gun_max_power
//   gun_damage_scale gun_can_fire gun_shot_speed gun_shot_cost
//   gun_reload_ticks gun_shot_damage gun_power_for_speed
//   gun_power_for_flight_time gun_lead gun_lead_point gun_aim_heading
//   gun_aim_pitch gun_fire gun_power gun_get_aim_heading gun_get_aim_pitch
//   gun_get_fire gun_get_power
// scanner: scanner_last scanner_proximity_range scanner_reach
//   scanner_arc_for_reach scanner_heading scanner_arc scanner_pitch
//   scanner_is_on scanner_on scanner_get_heading scanner_get_arc
//   scanner_get_pitch scanner_get_on
// sensors: sensors_contacts sensors_nearest sensors_cues sensors_contact
//   sensors_position_of
// tracker: tracker_cue tracker_nearest_bearing_rate tracker_velocity
//   tracker_position tracker_history tracker_last_seen tracker_configure
// nav: nav_zone nav_zone_margin nav_zone_contains nav_zone_distance_from
//   nav_storm nav_storm_margin nav_storm_contains nav_storm_distance_from
//   nav_hill nav_hill_margin nav_hill_contains nav_hill_distance_from
//   nav_wall_margin nav_pickups nav_nearest_pickup nav_field_distance
// score: score_me score_best score_armour
// angles: angles_normalize angles_angle_diff angles_bearing_to
//   angles_elevation_to angles_direction angles_distance angles_to_chassis
//   angles_from_chassis angles_clamp
// status: status_text status_value status_get_text status_get_value
// debug: debug_log
// raw: raw_number raw_text raw_has raw_flag raw_count raw_line raw_extra
// session: session_log
// Records: cy_contact, cy_vec3, cy_direction and the rest, in clunkyard.h.
// Angles are degrees from the +x axis; pitch is positive up.
// Manual: https://clunkyard.com/manual#wasm
const cy = @import("clunkyard.zig");

/// Enough to turn against the brake in the force rulesets.
const search_turn = 0.33;
/// How long to look again where a robot was last seen.
const memory_ticks = 60;
/// How long a dodge lasts: half a second.
const dodge_ticks = 10;
/// Degrees: sweeps the circle in half a second.
const search_arc = 40;
/// Units across at the target: it stays in the beam from tick to tick.
const hold_width = 60;
/// Degrees: the narrowest the beam holds.
const min_arc = 6;
/// Ticks of sightings the aim averages.
const window = 12;
/// Narrow sightings in the window before a shot.
const sightings = 8;
/// Ticks between looks around the target, for a nearer robot.
const look_every = 40;

var free_flight = false; // flying free, robots may be above or below
var forces = false; // the force rulesets: push the hull, not steer it
var last_slot: i32 = 0; // the robot seen most recently, 0 for none yet
var dodge_until: i32 = 0; // the tick the dodge ends
var dodges: i32 = 0; // how many dodges so far
var tick_rate: i32 = 0; // ticks a second

fn angleDiff(target: f64, current: f64) f64 {
    var diff: f64 = 0;
    _ = cy.angles_angle_diff(target, current, &diff);
    return diff;
}
fn bearingTo(from: cy.Vec3, to: cy.Vec3) f64 {
    var bearing: f64 = 0;
    _ = cy.angles_bearing_to(&from, &to, &bearing);
    return bearing;
}
fn elevationTo(from: cy.Vec3, to: cy.Vec3) f64 {
    var elevation: f64 = 0;
    _ = cy.angles_elevation_to(&from, &to, &elevation);
    return elevation;
}
fn unit(value: f64) f64 {
    return @max(-1.0, @min(1.0, value));
}

/// Drives towards a heading and an elevation, turning harder the smaller gain is.
fn steer(throttle: f64, heading: f64, elevation: f64, gain: f64, me_heading: f64, me_pitch: f64) void {
    _ = cy.drive_throttle(throttle);
    _ = cy.drive_turn(unit(angleDiff(heading, me_heading) / gain));
    _ = cy.drive_pitch_turn(unit((elevation - me_pitch) / gain));
}

/// One sighting of the target, as the sensors placed it.
const Sighting = struct { tick: i32, bearing_error: f64, x: f64, y: f64, z: f64 };
// The last `window` sightings of one robot. The core keeps a history
// (cy.tracker_history), but reading its 32 records costs more fuel than a
// turn can spare, so the robot keeps the few it uses itself.
var sighted: [window]Sighting = undefined;
var sighted_count: usize = 0; // sightings kept, in a ring
var sighted_slot: i32 = 0; // the robot they are of

var sighted_next: usize = 0; // where the next sighting goes, over the oldest

fn remember(target: *const cy.Contact, tick: i32) void {
    if (target.slot != sighted_slot) {
        sighted_count = 0;
        sighted_next = 0;
    }
    sighted_slot = target.slot;
    sighted[sighted_next] = .{ .tick = tick, .bearing_error = target.bearing_error, .x = target.position.x, .y = target.position.y, .z = target.position.z };
    sighted_next = (sighted_next + 1) % window;
    if (sighted_count < window) sighted_count += 1;
}

/// A straight line through the narrowest of the last `window` ticks'
/// sightings: where the robot is now and how fast it moves. Each sighting is
/// off by its bearing_error; the line averages that out. Ordinary least
/// squares, with time counted back from now so the line's value at now is its
/// intercept.
const Fit = struct { position: cy.Vec3, velocity: cy.Vec3, count: usize };
fn fit(tick: i32) ?Fit {
    const recent = sighted[0..sighted_count];
    var best: f64 = 1e9;
    for (recent) |s| {
        if (s.tick > tick - window) best = @min(best, s.bearing_error);
    }
    var n: f64 = 0;
    var st: f64 = 0;
    var stt: f64 = 0;
    var sx: f64 = 0;
    var sy: f64 = 0;
    var sz: f64 = 0;
    var stx: f64 = 0;
    var sty: f64 = 0;
    var stz: f64 = 0;
    const widest = 1.5 * best;
    for (recent) |s| {
        if (s.tick <= tick - window or s.bearing_error > widest) continue; // out of the window, or a look's wide sighting
        const dt: f64 = @floatFromInt(s.tick - tick);
        n += 1;
        st += dt;
        stt += dt * dt;
        sx += s.x;
        sy += s.y;
        sz += s.z;
        stx += dt * s.x;
        sty += dt * s.y;
        stz += dt * s.z;
    }
    if (n < 2) return null;
    const spread = n * stt - st * st;
    const rate: f64 = @floatFromInt(tick_rate);
    const kx = (n * stx - st * sx) / spread;
    const ky = (n * sty - st * sy) / spread;
    const kz = (n * stz - st * sz) / spread;
    return .{
        .position = .{ .x = (sx - kx * st) / n, .y = (sy - ky * st) / n, .z = (sz - kz * st) / n },
        .velocity = .{ .x = kx * rate, .y = ky * rate, .z = kz * rate },
        .count = @intFromFloat(n),
    };
}

/// The angle, in degrees, of a beam hold_width across at this range: atan by a rational fit, cheaper in fuel than a library call.
fn holdArc(range: f64) f64 {
    const x0: f64 = hold_width / 2.0 / range;
    const flip = x0 > 1;
    const x = if (flip) 1 / x0 else x0;
    const angle = x / (1 + 0.28125 * x * x);
    return 2 * (if (flip) 1.5707963 - angle else angle) * 57.29578;
}

fn start() void {
    _ = cy.match_tick_rate(&tick_rate);
    var is_3d: i32 = 0;
    var gravity: cy.Vec3 = .{};
    _ = cy.match_is_3d(&is_3d);
    _ = cy.arena_gravity(&gravity);
    free_flight = is_3d == 1 and gravity.z == 0;
    var control: i32 = 0;
    _ = cy.match_control(&control);
    forces = control == cy.CONTROL_FORCES;
}

fn turn() void {
    var me: cy.Vec3 = .{};
    var heading: f64 = 0;
    var pitch: f64 = 0;
    var tick: i32 = 0;
    _ = cy.me_position(&me);
    _ = cy.me_heading(&heading);
    _ = cy.me_pitch(&pitch);
    _ = cy.clock_tick(&tick);
    _ = cy.drive_brake(0.2);

    // Answers read only when their import says OK, so not cleared first:
    // clearing a struct costs fuel every turn.
    var target: cy.Contact = undefined;
    var seen: i32 = 0;
    var last: cy.Vec3 = undefined;
    var cue: cy.Cue = undefined;
    if (cy.sensors_nearest(&target) == cy.OK) {
        last_slot = target.slot;
        const throttle: f64 = if (target.range > 350) 0.7 else if (target.range < 200) -0.4 else 0.2;
        steer(throttle, target.bearing, target.elevation, 45, heading, pitch);
        remember(&target, tick);
        // Halve the beam each tick until it is hold_width across at the target:
        // narrow enough for a precise bearing, wide enough to keep it in. Every
        // look_every ticks widen it for a tick, so a nearer robot can be found.
        const hold = @max(min_arc, holdArc(target.range));
        var beam: cy.Scan = .{};
        _ = cy.scanner_last(&beam);
        const arc: f64 = if (@mod(tick, look_every) == 0) search_arc else @max(hold, @min(search_arc, beam.arc / 2));
        _ = cy.scanner_heading(target.bearing);
        _ = cy.scanner_arc(arc);
        _ = cy.scanner_pitch(target.elevation);
        // The heaviest shot that still covers the range in about a second,
        // aimed where the target will be, lobbed under gravity; straight at
        // it when no shot reaches it. An exact contact: gun_lead is the
        // intercept if the target holds its course. A noisy one: lead the
        // fitted line, and fire only once it rests on enough sightings.
        var power: f64 = 1;
        _ = cy.gun_power_for_flight_time(target.range, 1, &power);
        var aim: cy.Solution = .{};
        var found = false;
        var ready = true;
        if (target.bearing_error > 0) {
            if (fit(tick)) |line| {
                found = cy.gun_lead_point(&line.position, &line.velocity, power, &aim) == cy.OK;
                ready = found and line.count >= sightings;
            } else ready = false;
        } else found = cy.gun_lead(&target, power, &aim) == cy.OK;
        if (!found) aim = .{ .heading = target.bearing, .pitch = target.elevation, .time = 0 };
        _ = cy.gun_aim_heading(aim.heading);
        _ = cy.gun_aim_pitch(aim.pitch);
        var now: cy.Direction = .{};
        var can_fire: i32 = 0;
        _ = cy.gun_aim_now(&now);
        _ = cy.gun_can_fire(power, 10, &can_fire);
        const on_target = @abs(angleDiff(aim.heading, now.heading)) < 3 and @abs(aim.pitch - now.pitch) < 3;
        if (ready and on_target and can_fire == 1) {
            _ = cy.gun_fire();
            _ = cy.gun_power(power);
        }
    } else if (last_slot != 0 and cy.tracker_last_seen(last_slot, &seen) == cy.OK and tick - seen < memory_ticks and
        cy.tracker_position(last_slot, &last) == cy.OK)
    {
        // Head for where it was, sweeping a narrow scan across that bearing.
        const bearing = bearingTo(me, last);
        const elevation = if (free_flight) elevationTo(me, last) else 0;
        steer(0.7, bearing, elevation, 45, heading, pitch);
        _ = cy.scanner_heading(bearing + @as(f64, @floatFromInt(@mod(tick, 5) - 2)) * 8);
        _ = cy.scanner_arc(30);
        _ = cy.scanner_pitch(elevation);
    } else if (cy.tracker_cue(&cue) == cy.OK) {
        // Head the way the cue points, sweeping the scan across its error.
        const bearing = bearingTo(me, cue.position);
        const elevation = if (free_flight) elevationTo(me, cue.position) else 0;
        const @"error" = @min(cue.bearing_error, 30);
        steer(0.6, bearing, elevation, 45, heading, pitch);
        _ = cy.scanner_heading(bearing + @as(f64, @floatFromInt(@mod(tick, 5) - 2)) / 2 * @"error");
        _ = cy.scanner_arc(30);
        _ = cy.scanner_pitch(elevation);
    } else {
        steer(0.5, heading, 0, 45, heading, pitch);
        _ = cy.drive_turn(search_turn);
        // Sweeps the circle in half a second, flying free at three heights in turn.
        var scan: cy.Scan = .{};
        _ = cy.scanner_last(&scan);
        _ = cy.scanner_heading(scan.heading + 36);
        _ = cy.scanner_arc(40);
        _ = cy.scanner_pitch(if (free_flight) @as(f64, @floatFromInt(@mod(@divTrunc(tick, 10), 3) - 1)) * 35 else 0);
    }

    // A simple dodge: vary it, or predict the shooter. A muzzle cue means a
    // robot fired; for half a second swerve off the line of fire, left and
    // right in turn. More cues than the array holds (cy.SHORT) count as none
    // heard.
    var cues: [8]cy.Contact = undefined;
    var count: u32 = 0;
    if (tick >= dodge_until and cy.sensors_cues(&cues, cues.len, &count) == cy.OK) {
        for (cues[0..count]) |heard| {
            if (heard.source == cy.SOURCE_MUZZLE) {
                dodge_until = tick + dodge_ticks;
                dodges += 1;
                break;
            }
        }
    }
    if (tick < dodge_until) {
        // Turn is positive left, strafe positive right.
        const side: f64 = if (@mod(dodges, 2) == 1) 1 else -1;
        if (forces) {
            _ = cy.drive_throttle(0.5);
            _ = cy.drive_strafe(-side);
        } else {
            _ = cy.drive_throttle(1);
            _ = cy.drive_turn(side);
        }
    }

    // Low battery: drive gently so the shots can still be paid for.
    var charge: f64 = 0;
    var capacity: f64 = 0;
    _ = cy.battery_charge(&charge);
    _ = cy.battery_capacity(&capacity);
    if (charge < capacity / 4) {
        var throttle: f64 = 0;
        _ = cy.drive_get_throttle(&throttle);
        _ = cy.drive_throttle(throttle * 0.5);
    }

    // The storm drifts across the arena and hurts anything inside it. Near its
    // edge, step out across its path: at right angles to its drift, on the
    // side this robot is already on, so it passes by.
    var storm: cy.Storm = undefined;
    var margin: f64 = 0;
    if (cy.nav_storm(&storm) == cy.OK and cy.nav_storm_margin(&me, &margin) == cy.OK and margin > -60) {
        const away = bearingTo(storm.center, me);
        const drift = bearingTo(.{}, storm.velocity);
        const side: f64 = if (angleDiff(away, drift) < 0) -90 else 90;
        steer(1, drift + side, 0, 30, heading, pitch);
    }

    // Sudden death: head back inside the safe zone.
    var zone: cy.Zone = undefined;
    if (cy.nav_zone(&zone) == cy.OK and cy.nav_zone_margin(&me, &margin) == cy.OK and margin < 60) {
        const climb = if (zone.shape == cy.SHAPE_SPHERE) elevationTo(me, zone.center) else 0;
        steer(0.8, bearingTo(me, zone.center), climb, 30, heading, pitch);
    }
}

comptime {
    cy.exportRobot(start, turn);
}
