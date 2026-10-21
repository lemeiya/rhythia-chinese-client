extends Control

@export var saturation: float = 0.65
@export var value: float = 1
@export var alpha: float = 0.8

func _process(delta):
	modulate = Color.from_hsv(Rhythia.rainbow_t*0.1,saturation,value,alpha)
