extends CheckBox

func _process(_d):
	if button_pressed != Rhythia.invert_mouse:
		Rhythia.invert_mouse = button_pressed

func upd(): button_pressed = Rhythia.invert_mouse

func _ready():
	upd()
	Rhythia.connect("mods_changed", Callable(self, "upd"))
