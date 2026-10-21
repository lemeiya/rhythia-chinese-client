extends CheckBox

func _process(_d):
	if button_pressed != Rhythia.mod_extra_energy:
		Rhythia.mod_extra_energy = button_pressed

func upd(): button_pressed = Rhythia.mod_extra_energy

func _ready():
	upd()
	Rhythia.connect("mods_changed", Callable(self, "upd"))
