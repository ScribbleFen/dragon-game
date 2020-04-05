extends KinematicBody

var velocity := Vector3(0, 0, -10)
var turn := 0.0
var max_turn := 2.0
var tilt := 0.0
var max_tilt := 2.0
var turn_speed := 1.5
var max_speed := 15.0
var speed_modifier := 7.0

# Physics
var gravity = Vector3(0, -9.8, 0)
var drag := 0.1
var lift := 0.1
var thrust := 10.0
var thrust_acc := 20.0
var max_thrust := 40.0
var mass := 1.0

var physics := true

export(bool) var mouse_move := true
var mouse_speed := 0.01

# Thrust
var thrust_timer := Timer.new()
export var thrust_power := 100.0
export var thrust_length := 0.5

# Animation
onready var anim: AnimationPlayer = $Dragon/AnimationPlayer


# Called when the node enters the scene tree for the first time..
func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	add_child(thrust_timer)
	thrust_timer.one_shot = true


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func _input(event: InputEvent):
	if event is InputEventMouseMotion and Input.is_action_pressed("fly_mouse"):
		turn -= event.relative.x * turn_speed * mouse_speed
		tilt -= event.relative.y * turn_speed * mouse_speed
		turn = clamp(turn, -max_turn, max_turn)
		tilt = clamp(tilt, -max_tilt, max_tilt)
	elif event.is_action_pressed("fly_thrust") and thrust_timer.is_stopped():
		thrust_timer.start(thrust_length)
		anim.play("Flap", -1, anim.get_animation("Flap").length / thrust_length)

func _physics_process(dt: float):
	# Drag
	velocity = velocity.linear_interpolate(Vector3.ZERO, drag)
	
	if thrust_timer.time_left:
		thrust = bell_curve(thrust_timer.time_left) * (thrust_power / thrust_length)
		print(thrust)
	else:
		thrust = 0.0
	
	var thrust_force := -transform.basis.z * (thrust * dt)
	
	rotation.z = turn
	rotate_y(turn * dt)
	rotation.x = tilt
	var speed = max_speed + (-tilt * speed_modifier)
	velocity = -transform.basis.z * speed
	
	velocity += gravity
	
	velocity = move_and_slide(velocity)
	
	$Label.text = str("Hold right-click to steer. ", 
			"Speed: ", velocity.length(), "m/s ", 
			"Direction: ", rotation.y, 
			" Height: ", translation.y)

func bell_curve (x: float) -> float:
	# A bell curve between x = 0 and x = 1
	# Outputs a value between 0 and 1
	return (sin((x - 0.25) * 2.0 * PI) + 1.0) / 2.0
