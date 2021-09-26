extends Spatial

# Debug vars
export var camera: int = 0

func _ready():
	if camera == 0:
		$Player/Camera.current = true
	elif camera == 1:
		$Camera.current = true
