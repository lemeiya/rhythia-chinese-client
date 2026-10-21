extends CheckBox

func _process(_d):
	if button_pressed != Rhythia.mod_nofail:
		Rhythia.mod_nofail = button_pressed

func upd(): button_pressed = Rhythia.mod_nofail

func _ready():
	upd()
	Rhythia.connect("mods_changed", Callable(self, "upd"))
