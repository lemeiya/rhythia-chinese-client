extends Control

@onready var spin = $Spin
@export var percent: float = 0: set = _set_percent
@export var fill_color: Color = Color.WHITE: set = _set_fill
@export var empty_color: Color = Color("#6f6f6f"): set = _set_empty

var is_ready:bool = false

func _set_fill(v:Color):
	fill_color = v
	if is_ready: spin.material.set_shader_parameter("fill_color",fill_color)

func _set_empty(v:Color):
	empty_color = v
	if is_ready: spin.material.set_shader_parameter("empty_color",empty_color)

func _update_progress(value:float=percent):
	if is_ready: spin.material.set_shader_parameter("value",percent)

func _set_percent(value:float):
	percent = value
	_update_progress()

func _ready():
	spin.material = spin.material.duplicate()
	spin.material.set_shader_parameter("fill_color",fill_color)
	spin.material.set_shader_parameter("empty_color",empty_color)
	spin.material.set_shader_parameter("value",percent)
	is_ready = true
