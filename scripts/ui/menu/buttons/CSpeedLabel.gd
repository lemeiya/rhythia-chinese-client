extends Label

func upd():
	text = "C (%.0f%%)" % (Globals.speed_multi[Globals.SPEED_CUSTOM] * 100)

func _ready():
	upd()
	Rhythia.connect("mods_changed", Callable(self, "upd"))
	Rhythia.connect("speed_mod_changed", Callable(self, "upd"))
