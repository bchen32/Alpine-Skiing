extends KinematicBody

# Physical characteristics
export var gravity: float = 7
export var initial_vel: float = 5
export var min_vel: float = 0.1
export var max_angle_diff: float = 0.8 * PI / 2
export var min_friction: float = 0.0001
export var max_friction: float = 0.001

export var turn_angle_coeff: float = 1.5
export var rtc_angle_coeff: float = 0.3
export var friction_vel_coeff: float = 0.00001

# Vel
var velocity: Vector3 = Globals.downhill * initial_vel
var downhill_vel: Vector3 = Globals.downhill * initial_vel
var lateral_vel: Vector3 = Vector3()

# Death
signal death
var move: bool = false

func reset() -> void:
	velocity = Globals.downhill * initial_vel
	downhill_vel = Globals.downhill * initial_vel
	lateral_vel = Vector3()

func _physics_process(delta: float) -> void:
	# Only move when allowed
	if !move:
		return
	# Check angle difference between current velocity and downhill
	var angle_diff: float = Globals.downhill.angle_to(velocity)
	# Get signed difference
	if Globals.downhill.cross(velocity).dot(Globals.normal) < 0:
		angle_diff = -angle_diff
	# Inverted angle difference
	var inv_angle_diff: float = PI / 2 - abs(angle_diff)
	# Turn player if angle difference doesn't exceed max
	if Input.is_action_pressed('move_left') and angle_diff < max_angle_diff:
		velocity = velocity.rotated(Globals.normal, inv_angle_diff * turn_angle_coeff * delta)
	if Input.is_action_pressed('move_right') and angle_diff > -max_angle_diff:
		velocity = velocity.rotated(Globals.normal, -inv_angle_diff * turn_angle_coeff * delta)
	# Return to center force
	velocity = velocity.rotated(Globals.normal, -inv_angle_diff * turn_angle_coeff * angle_diff * rtc_angle_coeff * delta)
	# Give more forward velocity the more the player faces downhill
	var normalized_vel: Vector3 = velocity.normalized()
	velocity += normalized_vel * gravity * pow(inv_angle_diff, 2) * delta
	# Apply friction based on speed
	velocity *= 1 - clamp(velocity.length() * friction_vel_coeff, min_friction, max_friction)
	if velocity.length() < min_vel:
		velocity = normalized_vel * min_vel
	# Break velocity down into downhill and lateral components
	downhill_vel = velocity.project(Globals.downhill)
	lateral_vel = velocity - downhill_vel
	# Only move player along lateral velocity, downhill velocity will be simulated by moving obstacles uphill
	var move_collision: KinematicCollision = move_and_collide(lateral_vel * delta)
	if move_collision:
#		print('Player')
#		print(move_collision.collider)
		emit_signal('death')
