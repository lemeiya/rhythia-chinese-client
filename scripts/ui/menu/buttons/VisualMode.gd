extends CheckBox

func _process(_d):
	if button_pressed != Rhythia.visual_mode:
		Rhythia.visual_mode = button_pressed

func upd(): button_pressed = Rhythia.visual_mode

func _ready():
	upd()
	Rhythia.connect("mods_changed", Callable(self, "upd"))
