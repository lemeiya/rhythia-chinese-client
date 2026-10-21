extends CheckBox

@export var target: String

func upd():
#	print('scb "%s"' % name)
	button_pressed = Rhythia.get(target)

func _pressed():
	# var a = OS.get_ticks_usec()
#	print('scb "%s" press' % name)
	if button_pressed != Rhythia.get(target):
		Rhythia.set(target,button_pressed)

		if target == "enable_oldmenu":
			Globals.confirm_prompt.open(
				"You must restart for the changes to take effect",
				"Notice",
				[{text="Quit"}]
			)
			Globals.confirm_prompt.s_alert.play()
			var option = await Globals.confirm_prompt.option_selected
			Globals.confirm_prompt.close()
			Globals.confirm_prompt.s_next.play()
			Rhythia.save_settings()
			get_tree().quit()
#	print('scb "%s" press done, took %s usec' % [name,Globals.comma_sep(OS.get_ticks_usec() - a)])

func _ready():
	upd()
