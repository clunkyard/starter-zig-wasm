//! Generated from protocol/v2/api.json by protocol/v2/codegen/wasm-surfaces.js; do not edit. Run `make api`.
//!
//! Clunkyard WebAssembly ABI 4 for Zig: every clunkyard.* import at its
//! import name (sensors_nearest_v1, with sensors_nearest for the latest
//! version), the records and the constants. Each import returns a status
//! (OK, NONE for absent) and writes through pointers; each costs fuel.
//! exportRobot writes the module's two exports; build with -rdynamic, as
//! zig build-exe -target wasm32-freestanding -fno-entry -rdynamic
//! --export-memory, or Zig drops them.
//!
//!     const cy = @import("clunkyard.zig");
//!     fn turn() void {
//!         var target: cy.Contact = .{};
//!         if (cy.sensors_nearest(&target) == cy.OK) {
//!             _ = cy.gun_aim_heading(target.bearing);
//!             _ = cy.gun_fire();
//!         }
//!     }
//!     comptime {
//!         cy.exportRobot(null, turn);
//!     }

pub const API_VERSION = "2.0.0";
pub const API_MAJOR: i32 = 2;
pub const API_MINOR: i32 = 0;
/// Done.
pub const OK: i32 = 0;
/// Absent, which is not an error: no precise contact, a mechanic that is off, a shot that cannot reach, or a field that is unset.
pub const NONE: i32 = 1;
/// The buffer is too short; the length or count says how much is needed.
pub const SHORT: i32 = 2;
/// A number is NaN or infinite; the field is left unset.
pub const E_NOT_FINITE: i32 = -1;
/// A number is outside what the call accepts.
pub const E_RANGE: i32 = -2;
/// An argument is malformed: a null pointer, a slot out of range, text that is not UTF-8.
pub const E_ARGUMENT: i32 = -3;
/// The wrong point in the session, such as a state query before the first state.
pub const E_PHASE: i32 = -4;
/// The binding's API version is newer than the core's, or a different major.
pub const E_VERSION: i32 = -5;
/// A fault in the core. It is never the robot's fault; the handle resets on the next state.
pub const E_INTERNAL: i32 = -6;
/// source: none
pub const SOURCE_NONE: i32 = 0;
/// source: scan
pub const SOURCE_SCAN: i32 = 1;
/// source: proximity
pub const SOURCE_PROXIMITY: i32 = 2;
/// source: faint
pub const SOURCE_FAINT: i32 = 3;
/// source: beam
pub const SOURCE_BEAM: i32 = 4;
/// source: muzzle
pub const SOURCE_MUZZLE: i32 = 5;
/// source: motion
pub const SOURCE_MOTION: i32 = 6;
/// source: ping
pub const SOURCE_PING: i32 = 7;
/// mode: none
pub const MODE_NONE: i32 = 0;
/// mode: 2d
pub const MODE_TWO_D: i32 = 1;
/// mode: 3d
pub const MODE_THREE_D: i32 = 2;
/// ruleset: none
pub const RULESET_NONE: i32 = 0;
/// ruleset: classic
pub const RULESET_CLASSIC: i32 = 1;
/// ruleset: inertial-2d
pub const RULESET_INERTIAL_2D: i32 = 2;
/// ruleset: gravity-flat
pub const RULESET_GRAVITY_FLAT: i32 = 3;
/// ruleset: gravity-hills
pub const RULESET_GRAVITY_HILLS: i32 = 4;
/// ruleset: zero-g
pub const RULESET_ZERO_G: i32 = 5;
/// control: none
pub const CONTROL_NONE: i32 = 0;
/// control: direct
pub const CONTROL_DIRECT: i32 = 1;
/// control: forces
pub const CONTROL_FORCES: i32 = 2;
/// terrain_kind: none
pub const TERRAIN_KIND_NONE: i32 = 1;
/// terrain_kind: flat
pub const TERRAIN_KIND_FLAT: i32 = 2;
/// terrain_kind: hills
pub const TERRAIN_KIND_HILLS: i32 = 3;
/// shape: none
pub const SHAPE_NONE: i32 = 0;
/// shape: circle
pub const SHAPE_CIRCLE: i32 = 1;
/// shape: sphere
pub const SHAPE_SPHERE: i32 = 2;
/// shape: column
pub const SHAPE_COLUMN: i32 = 3;
/// pickup_kind: any
pub const PICKUP_KIND_ANY: i32 = 0;
/// pickup_kind: energy
pub const PICKUP_KIND_ENERGY: i32 = 1;
/// pickup_kind: health
pub const PICKUP_KIND_HEALTH: i32 = 2;
/// pickup_kind: armour
pub const PICKUP_KIND_ARMOUR: i32 = 3;
/// compute_unit: none
pub const COMPUTE_UNIT_NONE: i32 = 0;
/// compute_unit: operations
pub const COMPUTE_UNIT_OPERATIONS: i32 = 1;
/// compute_unit: fuel
pub const COMPUTE_UNIT_FUEL: i32 = 2;
/// compute_unit: cpu-ms
pub const COMPUTE_UNIT_CPU_MS: i32 = 3;
/// event: none
pub const EVENT_NONE: i32 = 0;
/// event: hello
pub const EVENT_HELLO: i32 = 1;
/// event: state
pub const EVENT_STATE: i32 = 2;
/// event: end
pub const EVENT_END: i32 = 3;

/// A vector in world axes. 24 bytes.
pub const Vec3 = extern struct {
    x: f64 = 0,
    y: f64 = 0,
    z: f64 = 0,
};

/// A rotation rate or torque about the robot's own axes. 24 bytes.
pub const Rotation = extern struct {
    yaw: f64 = 0,
    pitch: f64 = 0,
    roll: f64 = 0,
};

/// A direction as a heading and an elevation. 16 bytes.
pub const Direction = extern struct {
    heading: f64 = 0,
    pitch: f64 = 0,
};

/// The chassis axes as unit vectors in world axes. 72 bytes.
pub const AttitudeV1 = extern struct {
    forward: Vec3 = .{},
    right: Vec3 = .{},
    up: Vec3 = .{},
};
pub const Attitude = AttitudeV1;

/// What the previous tick applied to you, after the battery scaled the drive. 56 bytes.
pub const AppliedV1 = extern struct {
    force: Vec3 = .{},
    torque: Rotation = .{},
    brake: f64 = 0,
};
pub const Applied = AppliedV1;

/// The scan that produced this tick's contacts: the one your previous act asked for. 32 bytes.
pub const ScanV1 = extern struct {
    heading: f64 = 0,
    pitch: f64 = 0,
    arc: f64 = 0,
    range: f64 = 0,
};
pub const Scan = ScanV1;

/// A robot the sensors detect this tick. 72 bytes.
pub const ContactV1 = extern struct {
    slot: i32 = 0,
    source: i32 = 0,
    range: f64 = 0,
    bearing: f64 = 0,
    elevation: f64 = 0,
    bearing_error: f64 = 0,
    range_error: f64 = 0,
    position: Vec3 = .{},
};
pub const Contact = ContactV1;

/// The most accurate passive contact the Tracker holds: where to look, not where to shoot. 40 bytes.
pub const CueV1 = extern struct {
    source: i32 = 0,
    tick: i32 = 0,
    bearing_error: f64 = 0,
    position: Vec3 = .{},
};
pub const Cue = CueV1;

/// Where to aim for a shot fired now to meet a target, and when it meets it. 24 bytes.
pub const SolutionV1 = extern struct {
    heading: f64 = 0,
    pitch: f64 = 0,
    time: f64 = 0,
};
pub const Solution = SolutionV1;

/// The sudden-death safe zone. 40 bytes.
pub const ZoneV1 = extern struct {
    shape: i32 = 0,
    reserved: i32 = 0,
    radius: f64 = 0,
    center: Vec3 = .{},
};
pub const Zone = ZoneV1;

/// The storm now. 72 bytes.
pub const StormV1 = extern struct {
    shape: i32 = 0,
    reserved: i32 = 0,
    radius: f64 = 0,
    dps: f64 = 0,
    center: Vec3 = .{},
    velocity: Vec3 = .{},
};
pub const Storm = StormV1;

/// The king-of-the-hill zone now. 80 bytes.
pub const HillV1 = extern struct {
    shape: i32 = 0,
    holder: i32 = 0,
    contested: i32 = 0,
    moves_tick: i32 = 0,
    held_ticks: i32 = 0,
    best_held_ticks: i32 = 0,
    radius: f64 = 0,
    center: Vec3 = .{},
    next: Vec3 = .{},
};
pub const Hill = HillV1;

/// A cell on the field. 40 bytes.
pub const PickupV1 = extern struct {
    kind: i32 = 0,
    expires_tick: i32 = 0,
    amount: f64 = 0,
    position: Vec3 = .{},
};
pub const Pickup = PickupV1;

/// How the match charges compute against the battery. 16 bytes.
pub const ComputeV1 = extern struct {
    k: f64 = 0,
    quanta: i32 = 0,
    unit: i32 = 0,
};
pub const Compute = ComputeV1;

/// The match is 2D or 3D.
pub extern "clunkyard" fn match_mode(out: *i32) i32;
/// The ruleset in play.
pub extern "clunkyard" fn match_ruleset(out: *i32) i32;
/// Whether the drive sets speeds (direct) or forces.
pub extern "clunkyard" fn match_control(out: *i32) i32;
/// Robots in the match, you included; slots run 1 to this.
pub extern "clunkyard" fn match_robots(out: *i32) i32;
/// The match is 3D.
pub extern "clunkyard" fn match_is_3d(out: *i32) i32;
/// Ticks per second.
pub extern "clunkyard" fn match_tick_rate(out: *i32) i32;
/// The last tick the match can reach.
pub extern "clunkyard" fn match_max_ticks(out: *i32) i32;
/// The id the protocol gives the robot in a slot.
pub extern "clunkyard" fn robot_id(slot: i32, buf: [*]u8, capacity: u32, length: *u32) i32;
/// This tick, from 0.
pub extern "clunkyard" fn clock_tick(out: *i32) i32;
/// The match time in seconds.
pub extern "clunkyard" fn clock_seconds(out: *f64) i32;
/// Ticks left: match.max_ticks less this tick.
pub extern "clunkyard" fn clock_remaining_ticks(out: *i32) i32;
/// The arena runs from 0 to this on each axis.
pub extern "clunkyard" fn arena_size(out: *Vec3) i32;
/// The acceleration of gravity, units/s².
pub extern "clunkyard" fn arena_gravity(out: *Vec3) i32;
/// The kind of ground: none, flat or hills.
pub extern "clunkyard" fn arena_terrain_kind(out: *i32) i32;
/// The height of the ground at a point, interpolated as the arena does.
pub extern "clunkyard" fn arena_ground_height(x: f64, y: f64, out: *f64) i32;
/// Health left.
pub extern "clunkyard" fn me_health(out: *f64) i32;
/// Your centre.
pub extern "clunkyard" fn me_position(out: *Vec3) i32;
/// Your velocity, units/s.
pub extern "clunkyard" fn me_velocity(out: *Vec3) i32;
/// Your chassis heading.
pub extern "clunkyard" fn me_heading(out: *f64) i32;
/// Your chassis pitch; 0 in 2D.
pub extern "clunkyard" fn me_pitch(out: *f64) i32;
/// Your chassis roll; 0 in 2D and classic.
pub extern "clunkyard" fn me_roll(out: *f64) i32;
/// Your rotation rates, degrees/s.
pub extern "clunkyard" fn me_angular_velocity(out: *Rotation) i32;
/// Your chassis axes in world axes.
pub extern "clunkyard" fn me_attitude_v1(out: *AttitudeV1) i32;
/// You rest on the ground, under gravity.
pub extern "clunkyard" fn me_grounded(out: *i32) i32;
/// In 3D, the height of your underside above the ground.
pub extern "clunkyard" fn me_altitude(out: *f64) i32;
/// What the previous tick applied to you.
pub extern "clunkyard" fn me_applied_v1(out: *AppliedV1) i32;
/// Charge now, before this tick's regeneration and driving.
pub extern "clunkyard" fn battery_charge(out: *f64) i32;
/// Charge when full.
pub extern "clunkyard" fn battery_capacity(out: *f64) i32;
/// Charge regained each second.
pub extern "clunkyard" fn battery_regen(out: *f64) i32;
/// The drive fraction regeneration pays for forever.
pub extern "clunkyard" fn battery_sustainable_drive(out: *f64) i32;
/// How compute is charged, when the match charges it.
pub extern "clunkyard" fn battery_compute_v1(out: *ComputeV1) i32;
/// What holding a drive fraction costs each second, by hello.formulas.driveCost.
pub extern "clunkyard" fn battery_drive_cost(fraction: f64, out: *f64) i32;
/// The forces.lift that cancels gravity for a level robot; 0 without gravity.
pub extern "clunkyard" fn drive_hover_lift(out: *f64) i32;
/// Ask for direct controls this tick; the arena decides what they do in the ruleset.
pub extern "clunkyard" fn drive_throttle(value: f64) i32;
/// Ask for direct controls this tick; the arena decides what they do in the ruleset.
pub extern "clunkyard" fn drive_turn(value: f64) i32;
/// Ask for direct controls this tick; the arena decides what they do in the ruleset.
pub extern "clunkyard" fn drive_pitch_turn(value: f64) i32;
/// Ask for forces and torques this tick, in the force rulesets.
pub extern "clunkyard" fn drive_thrust(value: f64) i32;
/// Ask for forces and torques this tick, in the force rulesets.
pub extern "clunkyard" fn drive_strafe(value: f64) i32;
/// Ask for forces and torques this tick, in the force rulesets.
pub extern "clunkyard" fn drive_lift(value: f64) i32;
/// Ask for forces and torques this tick, in the force rulesets.
pub extern "clunkyard" fn drive_yaw_torque(value: f64) i32;
/// Ask for forces and torques this tick, in the force rulesets.
pub extern "clunkyard" fn drive_pitch_torque(value: f64) i32;
/// Ask for forces and torques this tick, in the force rulesets.
pub extern "clunkyard" fn drive_roll_torque(value: f64) i32;
/// Ask for forces and torques this tick, in the force rulesets.
pub extern "clunkyard" fn drive_brake(value: f64) i32;
/// What this tick's act holds for a drive field so far, as set.
pub extern "clunkyard" fn drive_get_throttle(out: *f64) i32;
/// What this tick's act holds for a drive field so far, as set.
pub extern "clunkyard" fn drive_get_turn(out: *f64) i32;
/// What this tick's act holds for a drive field so far, as set.
pub extern "clunkyard" fn drive_get_pitch_turn(out: *f64) i32;
/// What this tick's act holds for a drive field so far, as set.
pub extern "clunkyard" fn drive_get_thrust(out: *f64) i32;
/// What this tick's act holds for a drive field so far, as set.
pub extern "clunkyard" fn drive_get_strafe(out: *f64) i32;
/// What this tick's act holds for a drive field so far, as set.
pub extern "clunkyard" fn drive_get_lift(out: *f64) i32;
/// What this tick's act holds for a drive field so far, as set.
pub extern "clunkyard" fn drive_get_yaw_torque(out: *f64) i32;
/// What this tick's act holds for a drive field so far, as set.
pub extern "clunkyard" fn drive_get_pitch_torque(out: *f64) i32;
/// What this tick's act holds for a drive field so far, as set.
pub extern "clunkyard" fn drive_get_roll_torque(out: *f64) i32;
/// What this tick's act holds for a drive field so far, as set.
pub extern "clunkyard" fn drive_get_brake(out: *f64) i32;
/// Where the turret points now; a shot leaves along it.
pub extern "clunkyard" fn gun_aim_now(out: *Direction) i32;
/// Ticks until the gun can fire; 0 means it can fire this tick.
pub extern "clunkyard" fn gun_cooldown_ticks(out: *i32) i32;
/// The aim spread a shot would have at your speed now.
pub extern "clunkyard" fn gun_spread(out: *f64) i32;
/// The heaviest shot the battery pays for now; 0 when it cannot pay for the lightest.
pub extern "clunkyard" fn gun_max_power(out: *f64) i32;
/// The escalation multiplier on hit damage this tick.
pub extern "clunkyard" fn gun_damage_scale(out: *f64) i32;
/// The cooldown is 0 and the battery pays for a shot at this power and still holds the reserve.
pub extern "clunkyard" fn gun_can_fire(power: f64, reserve: f64, out: *i32) i32;
/// How fast a shot at this power flies, units/s, by hello.formulas.shotSpeed.
pub extern "clunkyard" fn gun_shot_speed(power: f64, out: *f64) i32;
/// What a shot at this power costs the battery, by hello.formulas.shotCost.
pub extern "clunkyard" fn gun_shot_cost(power: f64, out: *f64) i32;
/// The reload after a shot at this power, ticks, by hello.formulas.reloadTicks.
pub extern "clunkyard" fn gun_reload_ticks(power: f64, out: *f64) i32;
/// The damage of a hit at this power before escalation, by hello.formulas.shotDamage.
pub extern "clunkyard" fn gun_shot_damage(power: f64, out: *f64) i32;
/// The power whose shot flies at this speed, within the legal powers, by hello.formulas.powerForSpeed.
pub extern "clunkyard" fn gun_power_for_speed(speed: f64, out: *f64) i32;
/// The power whose shot covers this range in this time, within the legal powers.
pub extern "clunkyard" fn gun_power_for_flight_time(range: f64, seconds: f64, out: *f64) i32;
/// The aim at which a shot fired now meets the contact if it holds its tracked velocity; absent when no shot reaches it.
pub extern "clunkyard" fn gun_lead_v1(contact: *const ContactV1, power: f64, out: *SolutionV1) i32;
/// The aim at which a shot fired now meets a point moving at this velocity; absent when no shot reaches it.
pub extern "clunkyard" fn gun_lead_point_v1(position: *const Vec3, velocity: *const Vec3, power: f64, out: *SolutionV1) i32;
/// Ask the turret to turn toward a direction; it slews at gun.turnRate.
pub extern "clunkyard" fn gun_aim_heading(value: f64) i32;
/// Ask the turret to turn toward a direction; it slews at gun.turnRate.
pub extern "clunkyard" fn gun_aim_pitch(value: f64) i32;
/// Ask to fire this tick; the arena decides whether the gun and battery allow it.
pub extern "clunkyard" fn gun_fire() i32;
/// Ask to fire this tick; the arena decides whether the gun and battery allow it.
pub extern "clunkyard" fn gun_power(value: f64) i32;
/// What this tick's act holds for a gun field so far, as set.
pub extern "clunkyard" fn gun_get_aim_heading(out: *f64) i32;
/// What this tick's act holds for a gun field so far, as set.
pub extern "clunkyard" fn gun_get_aim_pitch(out: *f64) i32;
/// What this tick's act holds for a gun field so far, as set.
pub extern "clunkyard" fn gun_get_fire(out: *f64) i32;
/// What this tick's act holds for a gun field so far, as set.
pub extern "clunkyard" fn gun_get_power(out: *f64) i32;
/// The scan that produced this tick's contacts.
pub extern "clunkyard" fn scanner_last_v1(out: *ScanV1) i32;
/// Robots this close are detected in any direction.
pub extern "clunkyard" fn scanner_proximity_range(out: *f64) i32;
/// How far a scan of this arc reaches, by hello.formulas.reach.
pub extern "clunkyard" fn scanner_reach(arc: f64, out: *f64) i32;
/// The widest arc that still reaches this far, by hello.formulas.arcForReach.
pub extern "clunkyard" fn scanner_arc_for_reach(range: f64, out: *f64) i32;
/// Ask where the scanner points for the next state.
pub extern "clunkyard" fn scanner_heading(value: f64) i32;
/// Ask where the scanner points for the next state.
pub extern "clunkyard" fn scanner_arc(value: f64) i32;
/// Ask where the scanner points for the next state.
pub extern "clunkyard" fn scanner_pitch(value: f64) i32;
/// What this tick's act holds for a scanner field so far, as set.
pub extern "clunkyard" fn scanner_get_heading(out: *f64) i32;
/// What this tick's act holds for a scanner field so far, as set.
pub extern "clunkyard" fn scanner_get_arc(out: *f64) i32;
/// What this tick's act holds for a scanner field so far, as set.
pub extern "clunkyard" fn scanner_get_pitch(out: *f64) i32;
/// Every contact this tick: scan and proximity first, nearest first, then passive ones.
pub extern "clunkyard" fn sensors_contacts_v1(out: [*]ContactV1, capacity: u32, count: *u32) i32;
/// The nearest precise contact this tick. Passive contacts are never returned.
pub extern "clunkyard" fn sensors_nearest_v1(out: *ContactV1) i32;
/// This tick's passive contacts, most accurate (smallest bearing error) first.
pub extern "clunkyard" fn sensors_cues_v1(out: [*]ContactV1, capacity: u32, count: *u32) i32;
/// The precise contact for a robot this tick, if it was detected.
pub extern "clunkyard" fn sensors_contact_v1(slot: i32, out: *ContactV1) i32;
/// Where a contact places its robot: your position plus its range along its bearing and elevation.
pub extern "clunkyard" fn sensors_position_of_v1(contact: *const ContactV1, out: *Vec3) i32;
/// The most accurate passive contact heard in the last cue_ticks (60 by default), or absent.
pub extern "clunkyard" fn tracker_cue_v1(out: *CueV1) i32;
/// How fast the nearest contact's bearing turns, from two sightings.
pub extern "clunkyard" fn tracker_nearest_bearing_rate(out: *f64) i32;
/// The robot's tracked velocity; zero when it has no track.
pub extern "clunkyard" fn tracker_velocity(slot: i32, out: *Vec3) i32;
/// Where the robot was last seen, if it was.
pub extern "clunkyard" fn tracker_position(slot: i32, out: *Vec3) i32;
/// The tick the robot was last seen, if it was.
pub extern "clunkyard" fn tracker_last_seen(slot: i32, out: *i32) i32;
/// Sets the Tracker's parameters, in the robot's start only; after the first state it refuses with E_PHASE.
pub extern "clunkyard" fn tracker_configure(smoothing: f64, forget_ticks: i32, cue_ticks: i32) i32;
/// The sudden-death safe zone, once sudden death starts.
pub extern "clunkyard" fn nav_zone_v1(out: *ZoneV1) i32;
/// How far inside the zone a point is, by its shape's distance; absent while there is none.
pub extern "clunkyard" fn nav_zone_margin(point: *const Vec3, out: *f64) i32;
/// The point is inside the zone by at least the margin; absent while there is none.
pub extern "clunkyard" fn nav_zone_contains(point: *const Vec3, margin: f64, out: *i32) i32;
/// How far a point is from the zone's edge, 0 inside; absent while there is none.
pub extern "clunkyard" fn nav_zone_distance_from(point: *const Vec3, out: *f64) i32;
/// The storm, once it enters.
pub extern "clunkyard" fn nav_storm_v1(out: *StormV1) i32;
/// How far inside the storm a point is, by its shape's distance; absent while there is none.
pub extern "clunkyard" fn nav_storm_margin(point: *const Vec3, out: *f64) i32;
/// The point is inside the storm by at least the margin; absent while there is none.
pub extern "clunkyard" fn nav_storm_contains(point: *const Vec3, margin: f64, out: *i32) i32;
/// How far a point is from the storm's edge, 0 inside; absent while there is none.
pub extern "clunkyard" fn nav_storm_distance_from(point: *const Vec3, out: *f64) i32;
/// The hill, once it appears.
pub extern "clunkyard" fn nav_hill_v1(out: *HillV1) i32;
/// How far inside the hill a point is, by its shape's distance; absent while there is none.
pub extern "clunkyard" fn nav_hill_margin(point: *const Vec3, out: *f64) i32;
/// The point is inside the hill by at least the margin; absent while there is none.
pub extern "clunkyard" fn nav_hill_contains(point: *const Vec3, margin: f64, out: *i32) i32;
/// How far a point is from the hill's edge, 0 inside; absent while there is none.
pub extern "clunkyard" fn nav_hill_distance_from(point: *const Vec3, out: *f64) i32;
/// Every pickup on the field.
pub extern "clunkyard" fn nav_pickups_v1(out: [*]PickupV1, capacity: u32, count: *u32) i32;
/// The pickup of this kind nearest you by field distance, if there is one.
pub extern "clunkyard" fn nav_nearest_pickup_v1(kind: i32, out: *PickupV1) i32;
/// The distance between two points as the field measures it: in the plane under gravity, in space otherwise.
pub extern "clunkyard" fn nav_field_distance(a: *const Vec3, b: *const Vec3, out: *f64) i32;
/// Your score; absent when the match does not score.
pub extern "clunkyard" fn score_me(out: *f64) i32;
/// The best other robot's score; absent when the match does not score.
pub extern "clunkyard" fn score_best(out: *f64) i32;
/// Your armour; absent when the match has no objectives.
pub extern "clunkyard" fn score_armour(out: *f64) i32;
/// An angle brought into 0 to 360, exactly: degrees % 360, plus 360 when that is negative.
pub extern "clunkyard" fn angles_normalize(degrees: f64, out: *f64) i32;
/// The signed turn from current to target: normalize(target - current + 540) - 180.
pub extern "clunkyard" fn angles_angle_diff(target: f64, current: f64, out: *f64) i32;
/// The heading from one point to another.
pub extern "clunkyard" fn angles_bearing_to(from: *const Vec3, to: *const Vec3, out: *f64) i32;
/// The elevation from one point to another.
pub extern "clunkyard" fn angles_elevation_to(from: *const Vec3, to: *const Vec3, out: *f64) i32;
/// The unit vector along a heading and pitch.
pub extern "clunkyard" fn angles_direction(heading: f64, pitch: f64, out: *Vec3) i32;
/// The straight-line distance between two points.
pub extern "clunkyard" fn angles_distance(a: *const Vec3, b: *const Vec3, out: *f64) i32;
/// A value held within low and high.
pub extern "clunkyard" fn angles_clamp(value: f64, low: f64, high: f64, out: *f64) i32;
/// Set the status line; leaving it out keeps the last one.
pub extern "clunkyard" fn status_text(text: [*]const u8, text_length: u32) i32;
/// Set the status line; leaving it out keeps the last one.
pub extern "clunkyard" fn status_value(value: f64) i32;
/// What this tick's act holds for the status line so far, as set.
pub extern "clunkyard" fn status_get_text(buf: [*]u8, capacity: u32, length: *u32) i32;
/// What this tick's act holds for the status line so far, as set.
pub extern "clunkyard" fn status_get_value(out: *f64) i32;
/// The number at a path, if there is one.
pub extern "clunkyard" fn raw_number(path: [*]const u8, path_length: u32, out: *f64) i32;
/// The string at a path, if there is one.
pub extern "clunkyard" fn raw_text(path: [*]const u8, path_length: u32, buf: [*]u8, capacity: u32, length: *u32) i32;
/// Something is at the path.
pub extern "clunkyard" fn raw_has(path: [*]const u8, path_length: u32, out: *i32) i32;
/// The boolean at a path, if there is one.
pub extern "clunkyard" fn raw_flag(path: [*]const u8, path_length: u32, out: *i32) i32;
/// The length of the array at a path, if there is one.
pub extern "clunkyard" fn raw_count(path: [*]const u8, path_length: u32, out: *i32) i32;
/// The last line the session read: the hello, or the latest state.
pub extern "clunkyard" fn raw_line(buf: [*]u8, capacity: u32, length: *u32) i32;
/// Adds fields the API does not cover to this tick's act; a key the API writes (v, type, tick, drive, forces, aim, scan, fire, status) is refused with E_ARGUMENT.
pub extern "clunkyard" fn raw_extra(json: [*]const u8, json_length: u32) i32;
/// Writes a line to standard error, never to the protocol.
pub extern "clunkyard" fn session_log(line: [*]const u8, line_length: u32) i32;
/// The seed for the robot's own randomness.
pub extern "clunkyard" fn robot_seed(out: *u64) i32;

pub const me_attitude = me_attitude_v1;
pub const me_applied = me_applied_v1;
pub const battery_compute = battery_compute_v1;
pub const gun_lead = gun_lead_v1;
pub const gun_lead_point = gun_lead_point_v1;
pub const scanner_last = scanner_last_v1;
pub const sensors_contacts = sensors_contacts_v1;
pub const sensors_nearest = sensors_nearest_v1;
pub const sensors_cues = sensors_cues_v1;
pub const sensors_contact = sensors_contact_v1;
pub const sensors_position_of = sensors_position_of_v1;
pub const tracker_cue = tracker_cue_v1;
pub const nav_zone = nav_zone_v1;
pub const nav_storm = nav_storm_v1;
pub const nav_hill = nav_hill_v1;
pub const nav_pickups = nav_pickups_v1;
pub const nav_nearest_pickup = nav_nearest_pickup_v1;

/// The module's exports: start runs once after the hello (null for none),
/// turn once a state. Call it in a comptime block.
pub fn exportRobot(comptime start: ?fn () void, comptime turn: fn () void) void {
    const Exports = struct {
        fn clunkyardStart() callconv(.c) i32 {
            if (start) |run| run();
            return 0;
        }
        fn clunkyardTurn() callconv(.c) i32 {
            turn();
            return 0;
        }
    };
    @export(&Exports.clunkyardStart, .{ .name = "clunkyard_start" });
    @export(&Exports.clunkyardTurn, .{ .name = "clunkyard_turn" });
}
