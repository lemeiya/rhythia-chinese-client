extends CheckBox

func _process(_d):
	if button_pressed != Rhythia.mod_ghost:
		Rhythia.mod_ghost = button_pressed

func upd(): button_pressed = Rhythia.mod_ghost

func _ready():
	upd()
	Rhythia.connect("mods_changed", Callable(self, "upd"))
