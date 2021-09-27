extends KinematicBody

var velocity: Vector3 = Vector3()

signal death

func _physics_process(delta: float) -> void:
	var move_collision: KinematicCollision = move_and_collide(velocity * delta)
	if move_collision:
		emit_signal('death')
