extends CheckBox

func _pressed():
	get_parent().get_parent().get_node("MapRegistry/S/VBoxContainer").update_search_flip_name(
		!get_parent().get_parent().get_node("MapRegistry/S/VBoxContainer").flip_name
	)
	Rhythia.last_search_flip_name_sort = button_pressed

func _ready():
	button_pressed = Rhythia.last_search_flip_name_sort
	get_parent().get_parent().get_node("MapRegistry/S/VBoxContainer").update_search_flip_name(
		Rhythia.last_search_flip_name_sort
	)
