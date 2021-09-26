extends KinematicBody

# Physical characteristics
export var slope_angle: float = -PI / 6
export var gravity: float = 9.8
export var friction: float = 2
export var initial_vel: float = 1
export var min_vel: float = 0.5
export var max_angle_diff: float = 2 * PI / 5 
export var turn_vel_coeff: float = 0.5
export var angle_vel_coeff: float = 0.6

var downhill: Vector3 = Vector3.FORWARD.rotated(Vector3.RIGHT, slope_angle).normalized()
var normal: Vector3 = Vector3.RIGHT.cross(downhill).normalized()

# Vel
var velocity: Vector3 = downhill * initial_vel

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

func _physics_process(delta: float):
	# Check angle difference between current velocity and downhill
	var angle_diff: float = downhill.angle_to(velocity)
	# Inverted angle difference
	var inv_angle_diff: float = PI / 2 - abs(angle_diff)
	# Turn player if angle difference doesn't exceed max
	if Input.is_action_pressed('move_left') and angle_diff < max_angle_diff:
		velocity = velocity.rotated(normal, PI * inv_angle_diff * turn_vel_coeff * delta)
	if Input.is_action_pressed('move_right') and angle_diff > -max_angle_diff:
		velocity = velocity.rotated(normal, -PI * inv_angle_diff * turn_vel_coeff * delta)
#	Give more forward velocity the more the player faces downhill
	var normalized_vel: Vector3 = velocity.normalized()
	velocity += normalized_vel * gravity * pow(inv_angle_diff, 2) * angle_vel_coeff * delta
	velocity -= normalized_vel * friction * delta
	if velocity.length() < min_vel:
		velocity = normalized_vel * min_vel
	var move_collision: KinematicCollision = move_and_collide(velocity * delta)
	if move_collision:
		queue_free()
