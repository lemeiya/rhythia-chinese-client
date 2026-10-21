extends Control

@onready var pbar = $ProgressBar
@export var percent: float = 0: set = _set_percent

func _update_progress(value:float=percent):
	pbar.size.x = 280*value

func _set_percent(value:float):
	percent = value
	_update_progress()

func _ready():
	_update_progress()
