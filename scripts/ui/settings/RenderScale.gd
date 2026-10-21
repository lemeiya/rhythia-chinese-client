extends SpinBox

func _on_Scale_value_changed(value):
	var resolution = get_window().size
	if ((get_window().mode == Window.MODE_EXCLUSIVE_FULLSCREEN) or (get_window().mode == Window.MODE_FULLSCREEN)): resolution = DisplayServer.screen_get_size()
	Rhythia.render_scale = clampf(value, 0.5, 2.0)
	_apply_scale(resolution, value)

func viewport_size_changed():
	var resolution = get_window().size
	if ((get_window().mode == Window.MODE_EXCLUSIVE_FULLSCREEN) or (get_window().mode == Window.MODE_FULLSCREEN)): resolution = DisplayServer.screen_get_size()
	_apply_scale(resolution, Rhythia.render_scale)

func _apply_scale(_resolution:Vector2i, _scale:float):
	Rhythia.apply_render_scale()
	
# func _ready():
#	get_tree().get_root().connect("size_changed", self, "viewport_size_changed")
#	connect("changed", self, "_on_Scale_value_changed")
#	value = Rhythia.render_scale
#	viewport_size_changed()
