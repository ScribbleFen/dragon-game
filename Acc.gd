extends Control

export var line_thickness := 1.0
export var line_color := Color.black
export var circle_color := Color.black
export var point_count := 36
export var AA := true
export var scale := 10

onready var _from := get_viewport_rect().size/2 # Center of screen
onready var _to := _from
var _radius = 0.0

func _draw():
	draw_line(_from, _to, line_color, line_thickness, AA)
	draw_arc(_from, _radius, 0.0, 2*PI, point_count, circle_color)

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func draw_gauge(x := 0.0, y := 0.0, radius := 0.0) -> void:
	if radius > 0.0:
		var line := Vector2(x, y)
		var length := clamp(line.length() / radius, 0, 1.0)
		var to := line.normalized() * length
		_to = _from - to * radius * scale
		line_color = Color.from_hsv(to.angle() / (2*PI), 1, length)
	else:
		_to = _from
	_radius = radius * scale
	update()
