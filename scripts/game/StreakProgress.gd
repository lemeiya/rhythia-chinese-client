extends Control

@onready var parts:Array = [$Part]

@export var percent: float = 0: set = _set_percent
@export var fill_color: Color = Color.WHITE
@export var empty_color: Color = Color("#6f6f6f")
var _last_percent = -1

func _update_progress(value:float=percent):
	if _last_percent == value: return
	_last_percent = value
	var max_fill = floor(value*72)
	for i in range(72):
		if i+1 <= max_fill: parts[i].get_node("ColorRect").modulate = fill_color
		else: parts[i].get_node("ColorRect").modulate = empty_color

func _set_percent(value:float):
	percent = value
	_update_progress()

func _ready():
	for i in range(1,72):
		var n:Control = parts[0].duplicate()
		parts.append(n)
		add_child(n)
		n.rotation = 5*i
		n.move_to_front()
	_update_progress()
