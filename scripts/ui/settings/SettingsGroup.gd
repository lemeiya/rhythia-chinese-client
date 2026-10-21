extends VBoxContainer

@export var start_open: bool = false

func _toggle():
	$Group.visible = $Title/C.button_pressed

func _ready():
	$Title/C.button_pressed = start_open
	$Group.visible = start_open
	$Title/C.connect("pressed", Callable(self, "_toggle"))
