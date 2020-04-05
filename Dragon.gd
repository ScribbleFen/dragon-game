extends KinematicBody

var velocity := Vector3(0, 0, -20)
var turn := 0.0
var tilt := 0.0
var turn_speed := 3.0
var max_speed := 15.0
var speed_modifier := 7.0

# Physics
export var drag := true
export var gravity := true
export var lift := true
const g = 9.8
var gravity_force := Vector3(0, -g, 0)

var base_drag := 0.0
var base_lift := 0.0001

var drag_multiplier := 0.02
var lift_multiplier := 0.2

var turn_radius: float = INF

var physics := true

# Mouse controls
export(bool) var mouse_move := true
var mouse_speed := 0.01
var turn_buffer := 0.0
var turn_acc := 0.0
var tilt_buffer := 0.0
var tilt_acc := 0.0

# Thrust
var thrust_timer := Timer.new()
export var base_thrust_power := 1500.0
export var boost := 2.0
export var thrust_length := 1.0
var current_thrust_power := base_thrust_power

var thrust := 10.0

var total_energy := 100.0
var current_energy := 100.0
var glide_regen := 0.1
var dive_regen := 0.2

# Animation
onready var anim: AnimationPlayer = $Dragon/AnimationPlayer
onready var energy_bar: ColorRect = $UI/Energy

var is_diving := false setget dive


var debug := ""


# Called when the node enters the scene tree for the first time..
func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	add_child(thrust_timer)
	thrust_timer.one_shot = true
	anim.play("Flight")
	set_energy(total_energy)


func _input(event: InputEvent):
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if Input.is_action_pressed("fly_acc"):
			turn_acc -= event.relative.x * mouse_speed * turn_speed
			tilt_acc -= event.relative.y * mouse_speed * turn_speed
			$UI/Acc.draw_gauge(turn_acc, tilt_acc, turn_speed)
		elif !Input.is_action_pressed("fly_mouse"):
			turn_buffer -= event.relative.x * mouse_speed
			tilt_buffer -= event.relative.y * mouse_speed
	elif event.is_action_pressed("fly_dive"):
		dive(true)
	elif event.is_action_released("fly_dive"):
		dive(false)
	elif event.is_action_released("fly_acc"):
		tilt_acc = 0.0
		turn_acc = 0.0
		$UI/Acc.draw_gauge()


func _physics_process(dt: float):
	if Input.is_action_pressed("fly_thrust") and thrust_timer.is_stopped() and current_energy > 0:
		start_thrust()
		anim.play("Flap", -1, anim.get_animation("Flap").length / thrust_length)
		is_diving = false
#	var th := Input.get_action_strength("fly_thrust") - Input.get_action_strength("fly_brake")
#	th *= thrust_acc * dt
	
	if !mouse_move:
		var tu := Input.get_action_strength("fly_left") - Input.get_action_strength("fly_right")
		var ti := Input.get_action_strength("fly_up") - Input.get_action_strength("fly_down")
		tu *= turn_speed * dt
		ti *= turn_speed * dt
		turn_buffer += tu
		tilt_buffer += ti
	
	tilt_buffer += clamp(tilt_acc, -turn_speed, turn_speed) * dt
	turn_buffer += clamp(turn_acc, -turn_speed, turn_speed) * dt
	turn = calc_t(turn, turn_buffer, dt)
	tilt = calc_t(tilt, tilt_buffer, dt)
	
#	if tilt < -0.5:
#		dive(true)
#	else: 
#		dive(false)
	
#	thrust = clamp(thrust + th, -max_thrust, max_thrust)
	
	
	if physics:
		if thrust_timer.time_left:
			thrust = bell_curve(thrust_timer.time_left / thrust_length) * base_thrust_power * dt
			set_energy(current_energy - thrust * 0.03)
		else:
			thrust = 0.0
			var energy_regen := dive_regen if is_diving else glide_regen
			set_energy(current_energy + energy_regen)
		
		rotate(transform.basis.z, turn)
		turn_buffer -= turn
		turn = 0
		rotate(transform.basis.x, tilt)
		tilt_buffer -= tilt
		tilt = 0
		# Strength modulated by orientation of wing surface relative to velocity
		var aerodynamics := transform.basis.y.normalized().dot(velocity.normalized())
		
		var drag_direction := -velocity.normalized()
		var drag_strength := base_drag + (abs(aerodynamics) * drag_multiplier)
		var drag_force :=  drag_direction * drag_strength * velocity.length_squared()
		
		var lift_direction := transform.basis.x.cross(velocity).normalized()
		var lift_strength := base_lift + (-aerodynamics * lift_multiplier)
		var lift_force := lift_direction * lift_strength * velocity.length_squared()
		if lift_force.length_squared() > 10000.0:
			lift_force = lift_force.normalized() * 100
		
		
		var thrust_force := -transform.basis.z * thrust
		
		if is_diving:
			lift_force = Vector3.ZERO
			drag_force = Vector3.ZERO
			var target := velocity
			if (-transform.basis.z).angle_to(target) > 0.001:
				target = (-transform.basis.z.normalized()).slerp(target.normalized(), 0.1)
			look_at(global_transform.origin + target, transform.basis.y)
		
		drag_force = drag_force if drag else Vector3.ZERO
		lift_force = lift_force if lift else Vector3.ZERO
		gravity_force = gravity_force if gravity else Vector3.ZERO
		velocity += (drag_force + lift_force + thrust_force + gravity_force) * dt
		
		# r = v^2 / a
		var horizontal_force := Vector2(lift_force.x, lift_force.z).length()
		if horizontal_force != 0.0:
			var horizontal_velocity := Vector2(velocity.x, velocity.z).length()
			var turn_radius := velocity.length_squared() / horizontal_force
			var rot_y := ((horizontal_velocity * dt) / turn_radius) * sign(transform.basis.x.y)
			rotate_y(rot_y)
	
	else:
		rotation.z = turn
		rotate_y(turn * dt)
		rotation.x = tilt
		var speed = max_speed + (-tilt * speed_modifier)
		velocity = -transform.basis.z * speed
	
	
	velocity = move_and_slide(velocity)
	
	$Label.text = str("Controls: ", 
			"\n Steer with mouse. Hold space to accelerate, shift to dive", 
			"\n Hold middle-click for advanced maneuvers",
			"\n Speed: ", Vector2(velocity.x, velocity.z).length(), "m/s",
			"\n Airspeed: ", velocity.length(), "m/s",
			"\n Direction: ", rotation.y, 
			"\n Height: ", translation.y,
			"\n Debug: ", debug)
	
	transform.basis = transform.basis.orthonormalized()


func bell_curve (x: float) -> float:
	# A bell curve between x = 0 and x = 1
	# Outputs a value between 0 and 1
	return (sin((x - 0.25) * TAU) + 1.0) / 2.0


func calc_t(old_t: float, new_t: float, dt: float) -> float:
	debug = str(tilt) + ", " + str(tilt_buffer)
	var next_t: float = lerp(old_t, new_t, 0.1)
	
	if abs(next_t - old_t) > turn_speed * dt:
		return old_t + ((turn_speed * dt) * sign(next_t - old_t))
	else:
		return next_t


func dive(now_diving: bool) -> void:
	if is_diving != now_diving:
		if now_diving:
			is_diving = true
			anim.play("Dive")
			start_thrust(0.5, boost)
			thrust_timer.start(0.5)
		else:
			is_diving = false
			anim.play("Undive")


func start_thrust(length: float = thrust_length, power_multiplier:= 1.0) -> void:
	current_thrust_power = base_thrust_power * power_multiplier
	thrust_timer.start(length)


func set_energy(new_energy: float) -> void:
	current_energy = clamp(new_energy, 0.0, total_energy)
	energy_bar.rect_size.x = current_energy
	
	if current_energy == total_energy:
		energy_bar.hide()
	elif !energy_bar.visible:
		energy_bar.show()
	
