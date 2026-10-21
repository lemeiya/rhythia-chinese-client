extends Button

var debounce = false

func _pressed():
	if debounce or !Rhythia.selected_song: return
	debounce = true
	text = "Saving"
	Globals.file_sel.save_file(
		self,
		"_save_selected",
		PackedStringArray(["*.txt ; Text files"]),
		OS.get_system_dir(OS.SYSTEM_DIR_DOWNLOADS)
	)

func _save_selected(path:String):
	if path.is_empty():
		text = "Export map data"
		debounce = false
		return
	disabled = true
	Rhythia.selected_song.export_text(path)
	text = "Export map data"
	disabled = false
	debounce = false
