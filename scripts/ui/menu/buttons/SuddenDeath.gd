extends CheckBox

func _process(_d):
	if button_pressed != Rhythia.mod_sudden_death:
		Rhythia.mod_sudden_death = button_pressed

func upd(): button_pressed = Rhythia.mod_sudden_death

func _ready():
	upd()
	Rhythia.connect("mods_changed", Callable(self, "upd"))
