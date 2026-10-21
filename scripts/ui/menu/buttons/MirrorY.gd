extends CheckBox

func _process(_d):
	if button_pressed != Rhythia.mod_mirror_y:
		Rhythia.mod_mirror_y = button_pressed

func upd(): button_pressed = Rhythia.mod_mirror_y

func _ready():
	upd()
	Rhythia.connect("mods_changed", Callable(self, "upd"))
