extends CheckBox

func _process(_d):
	if button_pressed != Rhythia.mod_no_regen:
		Rhythia.mod_no_regen = button_pressed

func upd(): button_pressed = Rhythia.mod_no_regen

func _ready():
	upd()
	Rhythia.connect("mods_changed", Callable(self, "upd"))
