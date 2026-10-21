extends Button

var has_been_pressed:bool = false
func _pressed():
	Globals.confirm_prompt.open(
		"Are you sure? This will clear temporary maps!",
		"Reload All Content",
		[
			{ text = "Cancel" },
			{ text = "OK" }
		]
	)
	Globals.confirm_prompt.s_alert.play()
	var response:int = await Globals.confirm_prompt.option_selected
	Globals.confirm_prompt.close()
	if response == 1:
		Globals.confirm_prompt.s_next.play()
		await Globals.confirm_prompt.done_closing
		get_viewport().get_node("Menu").black_fade_target = true
		await get_tree().create_timer(0.35).timeout
		Rhythia.is_init = true
		get_tree().change_scene_to_file("res://scenes/init.tscn")
	else:
		Globals.confirm_prompt.s_back.play()
