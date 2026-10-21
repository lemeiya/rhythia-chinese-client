extends CheckBox

func _process(_d):
	if button_pressed != Rhythia.mod_chaos:
		Rhythia.mod_chaos = button_pressed

func upd(): button_pressed = Rhythia.mod_chaos

func _ready():
	upd()
	Rhythia.connect("mods_changed", Callable(self, "upd"))
