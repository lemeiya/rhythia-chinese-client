extends CheckBox

func _process(_d):
	if button_pressed != Rhythia.mod_earthquake:
		Rhythia.mod_earthquake = button_pressed

func upd(): button_pressed = Rhythia.mod_earthquake

func _ready():
	upd()
	Rhythia.connect("mods_changed", Callable(self, "upd"))
