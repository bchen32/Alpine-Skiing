extends KinematicBody

# Physical characteristics
export var slope_angle: float = -PI / 6
export var gravity: float = 9.8
export var initial_vel: float = 2
export var min_vel: float = 0.5
export var max_angle_diff: float = 2 * PI / 5
export var min_friction: float = 0.0
export var max_friction: float = 0.1

export var turn_vel_coeff: float = 0.5
export var rtc_vel_coeff: float = 0.5
export var angle_vel_coeff: float = 0.6
export var friction_vel_coeff: float = 0.00002

var downhill: Vector3 = Vector3.FORWARD.rotated(Vector3.RIGHT, slope_angle).normalized()
var normal: Vector3 = Vector3.RIGHT.cross(downhill).normalized()

# Vel
var velocity: Vector3 = downhill * initial_vel
var downhill_vel: Vector3 = downhill * initial_vel
var lateral_vel: Vector3 = Vector3()

# Death
signal death

func _physics_process(delta: float) -> void:
	# Check angle difference between current velocity and downhill
	var angle_diff: float = downhill.angle_to(velocity)
	# Get signed difference
	if downhill.cross(velocity).dot(normal) < 0:
		angle_diff = -angle_diff
	# Inverted angle difference
	var inv_angle_diff: float = PI / 2 - abs(angle_diff)
	# Turn player if angle difference doesn't exceed max
	if Input.is_action_pressed('move_left') and angle_diff < max_angle_diff:
		velocity = velocity.rotated(normal, PI * inv_angle_diff * turn_vel_coeff * delta)
	if Input.is_action_pressed('move_right') and angle_diff > -max_angle_diff:
		velocity = velocity.rotated(normal, -PI * inv_angle_diff * turn_vel_coeff * delta)
	# Return to center force
	velocity = velocity.rotated(normal, -PI * inv_angle_diff * turn_vel_coeff * angle_diff * rtc_vel_coeff * delta)
	# Give more forward velocity the more the player faces downhill
	var normalized_vel: Vector3 = velocity.normalized()
	velocity += normalized_vel * gravity * pow(inv_angle_diff, 2) * angle_vel_coeff * delta
	# Apply friction based on speed
	velocity *= 1 - clamp(velocity.length() * friction_vel_coeff, min_friction, max_friction)
	if velocity.length() < min_vel:
		velocity = normalized_vel * min_vel
	# Break velocity down into downhill and lateral components
	downhill_vel = velocity.project(downhill)
	lateral_vel = velocity - downhill_vel
	# Only move player along lateral velocity, downhill velocity will be simulated by moving obstacles uphill
	var move_collision: KinematicCollision = move_and_collide(lateral_vel * delta)
	if move_collision:
		emit_signal('death')
