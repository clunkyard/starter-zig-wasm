// A starter robot for rules v2, in Zig on WebAssembly ABI 4: it calls the
// robot core through the clunkyard.* imports in clunkyard.zig, next to this
// file. It sweeps a medium scan to find a robot, narrows the scan to hold it,
// leads it with shots whose power suits the range, fires only when the
// turret is on target, keeps battery back for driving, looks again where it
// last saw one, follows a passive cue when it has nothing better and steps
// out of the storm.
//
// The trade-offs (the imports answer with the numbers the hello set):
//   scan     a narrow arc reaches further; a wide one finds robots nearby
//   power    heavy shots hit harder for less battery, but fly slowly
//   battery  shots and driving share it, and it refills slowly
//   turret   it turns at a limited rate; cy.gun_aim_now is where it points now
//   fuel     every import costs fuel, so read each fact once a turn
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
//   me_angular_velocity me_attitude me_grounded me_altitude me_applied
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
//   scanner_get_heading scanner_get_arc scanner_get_pitch
// sensors: sensors_contacts sensors_nearest sensors_cues sensors_contact
//   sensors_position_of
// tracker: tracker_cue tracker_nearest_bearing_rate tracker_velocity
//   tracker_position tracker_last_seen tracker_configure
// nav: nav_zone nav_zone_margin nav_zone_contains nav_zone_distance_from
//   nav_storm nav_storm_margin nav_storm_contains nav_storm_distance_from
//   nav_hill nav_hill_margin nav_hill_contains nav_hill_distance_from
//   nav_pickups nav_nearest_pickup nav_field_distance
// score: score_me score_best score_armour
// angles: angles_normalize angles_angle_diff angles_bearing_to
//   angles_elevation_to angles_direction angles_distance angles_clamp
// status: status_text status_value status_get_text status_get_value
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

var free_flight = false; // flying free, robots may be above or below
var last_slot: i32 = 0; // the robot seen most recently, 0 for none yet

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

fn start() void {
    var is_3d: i32 = 0;
    var gravity: cy.Vec3 = .{};
    _ = cy.match_is_3d(&is_3d);
    _ = cy.arena_gravity(&gravity);
    free_flight = is_3d == 1 and gravity.z == 0;
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

    var target: cy.Contact = .{};
    var seen: i32 = 0;
    var last: cy.Vec3 = .{};
    var cue: cy.Cue = .{};
    if (cy.sensors_nearest(&target) == cy.OK) {
        last_slot = target.slot;
        const throttle: f64 = if (target.range > 350) 0.7 else if (target.range < 200) -0.4 else 0.2;
        steer(throttle, target.bearing, target.elevation, 45, heading, pitch);
        _ = cy.scanner_heading(target.bearing); // narrow: holds it, reaching about 735
        _ = cy.scanner_arc(20);
        _ = cy.scanner_pitch(target.elevation);
        // The heaviest shot that still covers the range in about a second,
        // aimed where the target will be, lobbed under gravity; straight at
        // it when no shot reaches it.
        var power: f64 = 1;
        _ = cy.gun_power_for_flight_time(target.range, 1, &power);
        var aim: cy.Solution = .{};
        if (cy.gun_lead(&target, power, &aim) != cy.OK) aim = .{ .heading = target.bearing, .pitch = target.elevation, .time = 0 };
        _ = cy.gun_aim_heading(aim.heading);
        _ = cy.gun_aim_pitch(aim.pitch);
        var now: cy.Direction = .{};
        var can_fire: i32 = 0;
        _ = cy.gun_aim_now(&now);
        _ = cy.gun_can_fire(power, 10, &can_fire);
        const on_target = @abs(angleDiff(aim.heading, now.heading)) < 3 and @abs(aim.pitch - now.pitch) < 3;
        if (on_target and can_fire == 1) {
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
    var storm: cy.Storm = .{};
    var margin: f64 = 0;
    if (cy.nav_storm(&storm) == cy.OK and cy.nav_storm_margin(&me, &margin) == cy.OK and margin > -60) {
        const away = bearingTo(storm.center, me);
        const drift = bearingTo(.{}, storm.velocity);
        const side: f64 = if (angleDiff(away, drift) < 0) -90 else 90;
        steer(1, drift + side, 0, 30, heading, pitch);
    }

    // Sudden death: head back inside the safe zone.
    var zone: cy.Zone = .{};
    if (cy.nav_zone(&zone) == cy.OK and cy.nav_zone_margin(&me, &margin) == cy.OK and margin < 60) {
        const climb = if (zone.shape == cy.SHAPE_SPHERE) elevationTo(me, zone.center) else 0;
        steer(0.8, bearingTo(me, zone.center), climb, 30, heading, pitch);
    }
}

comptime {
    cy.exportRobot(start, turn);
}
