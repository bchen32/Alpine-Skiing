extends Node

# Physical characteristics
export var slope_angle: float = -PI / 6

var downhill: Vector3 = Vector3.FORWARD.rotated(Vector3.RIGHT, slope_angle).normalized()
var normal: Vector3 = Vector3.RIGHT.cross(downhill).normalized()
