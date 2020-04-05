extends Position3D

export(NodePath) var target: NodePath
export(float) var speed := 0.1
onready var target_node: Spatial = get_node(target)

# Mouse look
var rot_x := 0.0
var rot_y := 0.0
var clean_basis: Basis
var mouse_speed = 0.01

func _input(event: InputEvent):
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseMotion and Input.is_action_pressed("fly_mouse"):
			rot_y -= event.relative.x * mouse_speed
			rot_x = clamp(rot_x - event.relative.y * mouse_speed, -PI/2, PI/2)
		elif event.is_action_pressed("fly_resetCam"):
			rot_x = 0
			rot_y = 0
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func _physics_process(dt: float):
	transform.basis = clean_basis
	var a := Quat(transform.basis)
	var b := Quat(target_node.transform.basis.orthonormalized())
	var c := a.slerp(b, speed)
	transform.basis = Basis(c)
	clean_basis = transform.basis
	rotate_object_local(Vector3.UP, rot_y)
	rotate_object_local(Vector3.RIGHT, rot_x)
	translation = translation.linear_interpolate(target_node.translation, speed)
