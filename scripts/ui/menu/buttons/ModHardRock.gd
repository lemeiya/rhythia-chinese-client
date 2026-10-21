extends CheckBox

func _process(_d):
	if button_pressed != Rhythia.mod_hardrock:
		Rhythia.mod_hardrock = button_pressed

func upd(): button_pressed = Rhythia.mod_hardrock

func _ready():
	upd()
	Rhythia.connect("mods_changed", Callable(self, "upd"))
