extends Camera

var speed = 0.01


# Called when the node enters the scene tree for the first time.
func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event: InputEvent):
	if event is InputEventMouseMotion and !Input.is_action_pressed("fly_mouse"):
		rotation.y -= event.relative.x * speed
		rotation.x -= event.relative.y * speed
		rotation.x = clamp(rotation.x, -PI/2, PI/2)
# Called every frame. 'delta' is the elapsed time since the previous frame.

