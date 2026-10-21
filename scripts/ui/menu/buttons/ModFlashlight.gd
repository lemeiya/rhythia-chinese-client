extends CheckBox

func _process(_d):
	if button_pressed != Rhythia.mod_flashlight:
		Rhythia.mod_flashlight = button_pressed

func upd(): button_pressed = Rhythia.mod_flashlight

func _ready():
	upd()
	Rhythia.connect("mods_changed", Callable(self, "upd"))
