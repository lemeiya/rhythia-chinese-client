extends CheckBox

@export var target: String

func upd():
#	print('scb "%s"' % name)
	button_pressed = Rhythia.get(target)
	get_parent().get_parent().get_node("MapRegistry/S/VBoxContainer").show_online_maps = button_pressed

func _pressed():
	if button_pressed != Rhythia.get(target):
		Rhythia.set(target,button_pressed)
	get_parent().get_parent().get_node("MapRegistry/S/VBoxContainer").update_search_showonline(
		Rhythia.last_search_incl_online
	)
	get_parent().get_parent().get_node("MapRegistry/S/VBoxContainer").show_online_maps = button_pressed

func _ready():
	upd()
	get_parent().get_parent().get_node("MapRegistry/S/VBoxContainer").update_search_showonline(
		Rhythia.last_search_incl_online
	)
