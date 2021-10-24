extends KinematicBody

signal death

var velocity: Vector3 = Vector3()


func _physics_process(delta: float) -> void:
	var move_collision: KinematicCollision = move_and_collide(velocity * delta)
	if move_collision:
#		print(self)
#		print(move_collision.collider)
		emit_signal("death")
