extends CheckBox

func _pressed():
	if button_pressed != ((get_window().mode == Window.MODE_EXCLUSIVE_FULLSCREEN) or (get_window().mode == Window.MODE_FULLSCREEN)):
		get_window().mode = Window.MODE_EXCLUSIVE_FULLSCREEN if (button_pressed) else Window.MODE_WINDOWED

func _ready():
	visible = OS.has_feature("pc")
#	OS.window_fullscreen = true
#	button_pressed = true
