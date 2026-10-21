extends CheckBox

func _process(_d):
	if button_pressed != Rhythia.mod_mirror_x:
		Rhythia.mod_mirror_x = button_pressed

func upd(): button_pressed = Rhythia.mod_mirror_x

func _ready():
	upd()
	Rhythia.connect("mods_changed", Callable(self, "upd"))
