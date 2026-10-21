extends Panel

var dir:Directory = Directory.new()
var file:File = File.new()

@export var cover_placeholder: Texture2D

var song:Song

var maptype:int = -1
var filetype:int = -1
var opening:int = -1
var step:int = 0
var path:String = ""
var musicPath:String = ""
var dataPath:String = ""
var difficulty_id:int = -1

enum {
	T_TXT,
	T_SSPM,
	T_VULNUS,
	T_SSPMR,
}
enum {
	F_DIR,
	F_ZIP,
}
enum {
	FO_VZIP,
	FO_VDIR,
	FO_COVER,
	FO_SSPM,
	FO_TXT,
	FO_SONG,
}

var txt_using_manual_id:bool = false

func check_txt_requirements():
	if song.rawData == "":
		$TxtFile/done.disabled = true
		$TxtFile/done/Title.text = "Map data required"
	elif !song.musicFile:
		$TxtFile/done.disabled = true
		$TxtFile/done/Title.text = "Music file required"
	elif song.name.to_lower() == "artist name - song name":
		$TxtFile/done.disabled = true
		$TxtFile/done/Title.text = "Song name required"
	elif song.creator.to_lower() == "mapper":
		$TxtFile/done.disabled = true
		$TxtFile/done/Title.text = "Mapper required"
	else:
		if Rhythia.registry_song.idx_id.has(song.id) and !Rhythia.registry_song.get_item(song.id).is_online:
			$TxtFile/done.disabled = true
			$TxtFile/done/Title.text = tr("ID in use")
		else:
			$TxtFile/done.disabled = false
			$TxtFile/done/Title.text = "Finish"

func check_txt(txt:String,is_raw:bool=false):
	if is_raw: song.songType = Globals.MAP_RAW
	else: song.songType = Globals.MAP_TXT
	if txt.split(",").size() >= 2 and txt.split(",")[1].split("|").size() == 3:
		song.loadRawData(txt)
		$TxtFile/H/data/Info.set("theme_override_colors/font_color",Color(0.5,1,0.5))
		if txt.length() > 25: $TxtFile/H/data/Info.text = txt.substr(0,25) + "..."
		else: $Label.text = txt
		$TxtFile/H/data/text.text = txt
		check_txt_requirements()
	else:
		song.rawData = ""
		$TxtFile/H/data/Info.text = "Invalid map data"
		$TxtFile/H/data/Info.set("theme_override_colors/font_color",Color(1,0.5,0.5))
		$TxtFile/H/data/text.text = ""
		check_txt_requirements()

func txt_song_preview():
	if $TxtFile/H/audio/player.playing:
		$TxtFile/H/audio/preview/Title.text = "Preview"
		$TxtFile/H/audio/player.stop()
		if Rhythia.play_menu_music:
			get_node("../MenuSong").play()
	elif !$TxtFile/H/audio/preview.disabled:
		$TxtFile/H/audio/preview/Title.text = "Stop previewing"
		get_node("../MenuSong").stop()
		$TxtFile/H/audio/player.play()

func do_txt_paste():
	$TxtFile/H/data.custom_minimum_size.y = 150
	$TxtFile/H/data/file.visible = false
	$TxtFile/H/data/paste.visible = false
	$TxtFile/H/data/text_done.visible = true
	$TxtFile/H/data/text.visible = true
	$TxtFile/H/data/text.grab_focus()
	$TxtFile/H/data/text.select_all()

func end_txt_paste():
	$TxtFile/H/data.custom_minimum_size.y = 60
	$TxtFile/H/data/file.visible = true
	$TxtFile/H/data/paste.visible = true
	$TxtFile/H/data/text_done.visible = false
	$TxtFile/H/data/text.visible = false
	check_txt($TxtFile/H/data/text.text,true)

func reset_text_edit_screen():
	txt_using_manual_id = false
	edit_pop = true
	song = Song.new(
		generate_id(tr("Artist Name - Song Name"),"mapper"),
		"Artist Name - Song Name",
		"mapper"
	)
	song.songType = Globals.MAP_TXT
	print(Globals.MAP_TXT)
	print(song.songType)
	$TxtFile/H/data.custom_minimum_size.y = 60
	$TxtFile/H/data/file.visible = true
	$TxtFile/H/data/paste.visible = true
	$TxtFile/H/data/text_done.visible = false
	$TxtFile/H/data/text.visible = false
	$TxtFile/H/data/text.text = ""
	
	$TxtFile/H/E/Info/Id.text = song.id
	$TxtFile/H/E/Info/Id/T.text = "auto"
	$TxtFile/H/E/Info/SongName.text = song.name
	$TxtFile/H/E/Info/SongName/T.text = song.name
	$TxtFile/H/E/Info/Difficulty.text = tr("Difficulty") + ": " + Globals.difficulty_names[song.difficulty]
	$TxtFile/H/E/Info/Mapper.text = tr("Mapper") + ": %s" % song.creator
	$TxtFile/H/E/Info/Mapper/T.text = song.creator
	$TxtFile/H/E/Info/Difficulty/B.selected = (song.difficulty + 1)
	
	$TxtFile/H/data/Info.text = "Required"
	$TxtFile/H/data/Info.set("theme_override_colors/font_color",Color(1,0.5,0.5))
	$TxtFile/H/audio/Info.text = "Required"
	$TxtFile/H/audio/Info.set("theme_override_colors/font_color",Color(1,0.5,0.5))
	$TxtFile/H/audio/preview.disabled = true
	$TxtFile/H/audio/preview.modulate = Color(0.5,0.5,0.5)
	$TxtFile/H/audio/preview/Title.text = "Preview"
	$TxtFile/H/audio/player.stop()
	
	$TxtFile/H/E/Cover/T.texture = load("res://assets/images/ui/placeholder_dark.jpg")
	$TxtFile/H/E/Cover/C.disabled = true
	$TxtFile/H/E/Cover/C.button_pressed = false
	
	check_txt_requirements()
	
	edit_pop = false

func select_type(type:int):
	if type == T_VULNUS:
		maptype = T_VULNUS
		step = 1
		$SelectType.visible = false
		$VulnusFile.visible = true
	elif type == T_SSPM:
		print("opening sspm")
		opening = FO_SSPM
		Globals.file_sel.open_file(
			self,
			"file_selected",
			PackedStringArray(["*.sspm ; Sound Space Plus map"]),
			false,
			#"~/Downloads"
			OS.get_system_dir(OS.SYSTEM_DIR_DOWNLOADS)
		)
	elif type == T_TXT:
		reset_text_edit_screen()
		maptype = T_TXT
		step = 1
		$SelectType.visible = false
		$TxtFile.visible = true

func sel_filetype(type:int):
	print(type)
	if maptype == T_VULNUS:
		print("opening a vulnus map")
		if type == F_ZIP:
			print("opening vulnus zip")
			opening = FO_VZIP
			Globals.file_sel.open_file(
				self,
				"file_selected",
				PackedStringArray(["*.zip, *.rar, *.7z, *.gz, *.vmap ; archive files"]),
				false,
				#"~/Downloads"
				OS.get_system_dir(OS.SYSTEM_DIR_DOWNLOADS)
			)
		elif type == F_DIR:
			print("opening vulnus folder")
			opening = FO_VDIR
			
			Globals.file_sel.open_folder(
				self,
				"folder_selected",
				#"~/Downloads"
				OS.get_system_dir(OS.SYSTEM_DIR_DOWNLOADS)
			)
	elif maptype == T_TXT:
		if type == FO_TXT:
			opening = FO_TXT
			Globals.file_sel.open_file(
				self,
				"file_selected",
				PackedStringArray(["*.txt ; Text files"]),
				false,
				#"~/Downloads"
				OS.get_system_dir(OS.SYSTEM_DIR_DOWNLOADS)
			)
		elif type == FO_SONG:
			opening = FO_SONG
			Globals.file_sel.open_file(
				self,
				"file_selected",
				PackedStringArray(["*.mp3, *.ogg ; Audio files"]),
				false,
				#"~/Downloads"
				OS.get_system_dir(OS.SYSTEM_DIR_DOWNLOADS)
			)

const valid_chars = "0123456789abcdefghijklmnopqrstuvwxyz_-"

func generate_id(sname:String,mapper:String):
	var txt:String = ""
	if mapper.length() != 0:
		for i in range(mapper.length()):
			if mapper.to_lower()[i].is_subsequence_of(valid_chars):
				txt += mapper.to_lower()[i]
			elif mapper[i] == " " and txt[txt.length()-1] != "_":
				txt += "_"
		if txt[txt.length()-1] != "_": txt += "_"
	for i in range(sname.length()):
		if sname.to_lower()[i].is_subsequence_of(valid_chars):
			txt += sname.to_lower()[i]
		elif sname[i] == " " and txt[txt.length()-1] != "_": txt += "_"
	return txt.trim_prefix("_").trim_suffix("_")

func generate_id_with_dname(sname:String,mapper:String,dname:String):
	var txt:String = ""
	if mapper.length() != 0:
		for i in range(mapper.length()):
			if mapper.to_lower()[i].is_subsequence_of(valid_chars):
				txt += mapper.to_lower()[i]
			elif mapper[i] == " " and txt[txt.length()-1] != "_":
				txt += "_"
		if txt[txt.length()-1] != "_": txt += "_"
	for i in range(sname.length()):
		if sname.to_lower()[i].is_subsequence_of(valid_chars):
			txt += sname.to_lower()[i]
		elif sname[i] == " " and txt[txt.length()-1] != "_": txt += "_"
	txt += "_"
	for i in range(dname.length()):
		if dname.to_lower()[i].is_subsequence_of(valid_chars):
			txt += dname.to_lower()[i]
		elif dname[i] == " " and txt[txt.length()-1] != "_": txt += "_"
	return txt.trim_prefix("_").trim_suffix("_")


var edit_pop:bool = false
func populate_edit_screen():
	edit_pop = true
	$Edit/Info/Id.text = song.id
	$Edit/Info/Id/T.text = song.id
	$Edit/Info/SongName.text = song.name
	$Edit/Info/SongName/T.text = song.name
	$Edit/Info/Difficulty.text = "Difficulty: " + Globals.difficulty_names[song.difficulty]
	$Edit/Info/Mapper.text = tr("Mapper") + ": %s" % song.creator
	$Edit/Info/Mapper/T.text = song.creator
	$Edit/Info/Difficulty/B.selected = (song.difficulty + 1)
	if song.has_cover:
		$Edit/Cover/T.texture = song.cover
		$Edit/Cover/C.disabled = false
		$Edit/Cover/C.button_pressed = true
	else:
		$Edit/Cover/T.texture = load("res://assets/images/ui/placeholder_dark.jpg")
		$Edit/Cover/C.disabled = true
		$Edit/Cover/C.button_pressed = false
	
	if Rhythia.registry_song.idx_id.has(song.id):
		$Edit/done.disabled = true
		$Edit/done/Title.text = "ID in use"
	elif song.id == "_NOTREADY":
		$Edit/done.disabled = true
		$Edit/done/Title.text = "Not ready"
	else:
		$Edit/done.disabled = false
		$Edit/done/Title.text = "Finish"
	edit_pop = false

func import_vulnus_folder():
	print("Locating meta.json...")
	await get_tree().process_frame
	
	dir.open(path)
	if !dir.file_exists("meta.json"):
		print("Possible nested folder - searching for meta.json AAAAAAAAAAAAAAAAAAAA")
		await get_tree().process_frame
		print('list_dir_begin before')
		dir.list_dir_begin() # TODOConverter3To4 fill missing arguments https://github.com/godotengine/godot/pull/40547
		var n = dir.get_next()
		while n:
			n = dir.get_next()
			print(n)
			if dir.file_exists(n.path_join("meta.json")):
				print("Found meta.json in '%s'" % n)
				await get_tree().process_frame
				path = path.path_join(n)
				break
		dir.list_dir_end()
		if path == Globals.p("user://temp"): # Meta.json wasn't found anywhere
			print("couldn't find meta.json")
			$VulnusFile/Error.text = "Missing meta.json (check if the zip file contains a folder, and, if it does, extract it)"
			$VulnusFile/Error.visible = true
			return
		else:
			print("found meta.json at %s" % path)
	
	print("Located! Loading meta.json...")
	await get_tree().process_frame
	var res = file.open(path.path_join("meta.json"),File.READ)
	if res != OK:
		print("meta.json: file open error %s" % res)
		$VulnusFile/Error.text = "meta.json: error opening file (file error %s)" % res
		$VulnusFile/Error.visible = true
		return
	
	var metatxt:String = file.get_as_text()
	file.close()
	print("Loaded! Reading metadata now...")
	await get_tree().process_frame
	var test_json_conv = JSON.new()
	test_json_conv.parse(metatxt)
	var meta:Dictionary = test_json_conv.get_data()
	print("Parsed!")
	await get_tree().process_frame
	var artist:String = meta.get("_artist","Unknown Artist")
	var difficulties:Array = meta.get("_difficulties",[])
	var mappers:Array = meta.get("_mappers",[])
	var music_path:String = meta.get("_music","**missing**")
	var title:String = meta.get("_title","Unknown Song")
	
	print("Data loaded! Making sure we have everything we need...")
	await get_tree().process_frame
	
	if difficulties.size() == 0:
		print("no difficulties")
		$VulnusFile/Error.text = "No difficulties defined - cannot get map data"
		$VulnusFile/Error.visible = true
		return
	if music_path == "**missing**" or !music_path.is_valid_filename():
		print("invalid music path")
		$VulnusFile/Error.text = "Path3D to music is missing or invalid"
		$VulnusFile/Error.visible = true
		return
	
	if !file.file_exists(path.path_join(music_path)):
		print("music file doesn't exist")
		$VulnusFile/Error.text = "Music file does not exist (%s)" % [music_path]
		$VulnusFile/Error.visible = true
		return
	
	print("Everything seems to be present!")
	print("Building metadata...")
	await get_tree().process_frame
	
	var conc:String = ""
	for i in range(mappers.size()):
		if i != 0: conc += ", "
		conc += mappers[i]
	
	var songname = "%s - %s" % [artist,title]
	var id = generate_id(songname,conc)
	print("Everything is ready! Loading map...")
	await get_tree().process_frame
	
	song = Song.new(id,songname,conc)
	
	if difficulties.size() == 1:
		if !file.file_exists(path.path_join(difficulties[0])):
			print("map data file doesn't exist")
			$VulnusFile/Error.text = "Map data file does not exist (%s)" % [difficulties[0]]
			$VulnusFile/Error.visible = true
			return
		song.setup_from_vulnus_json("%s/%s" % [path,difficulties[0]], "%s/%s" % [path,music_path])
		
		var cover = Globals.imageLoader.load_if_exists(path.path_join("cover"))
		if cover:
			song.cover = cover
			song.has_cover = true
		
		print("IMPORTED SUCCESS!!! PARTY TIME!")
		$VulnusFile/Success.text = "map imported as %s!" % [id]
		$VulnusFile/Success.visible = true
		await get_tree().process_frame
		
		$VulnusFile.visible = false
		populate_edit_screen()
		$Edit.visible = true
	else:
		$VulnusFile.visible = false
		populate_vmap_difficulty_sel()
		$SelectDifficulty.visible = true

func populate_vmap_difficulty_sel():
	for n in $SelectDifficulty/S/V/L.get_children():
		if n.name != "Item":
			n.queue_free()
	var dlist:Array = song.get_vulnus_map_difficulty_list(path)
	for i in range(dlist.size()):
		var btn = $SelectDifficulty/S/V/L/Item.duplicate()
		$SelectDifficulty/S/V/L.add_child(btn)
		btn.get_node("L").text = dlist[i]
		btn.visible = true
		btn.connect("pressed", Callable(self, "vmap_difficulty_sel").bind(i))

func import_vmap_with_difficulty(difficulty_id:int,is_loop:bool=true):
	var result = song.load_from_vulnus_map(path,difficulty_id)
	if result:
		if difficulty_id == 0:
			song.id = generate_id(song.song,song.creator)
		else:
			song.id = generate_id_with_dname(song.song,song.creator,song.custom_data.difficulty_name)
		
		if is_loop:
			result = song.convert_to_sspm()
			
			if result == "Converted!":
				Rhythia.registry_song.check_and_remove_id(song.id)
				Rhythia.registry_song.add_sspm_map("user://maps/%s.sspm" % song.id)
				return 1
			else:
				$Finish/Error.text = result + (" (%s)" % song.custom_data.difficulty_name)
				$Finish/Error.visible = true
				$Finish/Success.visible = false
				$Finish/Wait.visible = false
				$Finish/ok.visible = true
				$SelectDifficulty.visible = false
				$Finish.visible = true
				return -1
		else:
			$SelectDifficulty.visible = false
			finish_map()
			return 1
	else:
		return 0

func vmap_difficulty_sel(i:int):
	var res = file.open(path.path_join("meta.json"),File.READ)
	if res != OK:
		print("meta.json: file open error %s" % res)
		$Finish/Error.text = "meta.json: error opening file (file error %s)" % res
		$Finish/Error.visible = true
		$Finish/Success.visible = false
		$Finish/Wait.visible = false
		$Finish/ok.visible = true
		$SelectDifficulty.visible = false
		$Finish.visible = true
		return
	
	var metatxt:String = file.get_as_text()
	file.close()
	print("Loaded! Reading metadata now...")
	await get_tree().process_frame
	var test_json_conv = JSON.new()
	test_json_conv.parse(metatxt)
	var meta:Dictionary = test_json_conv.get_data()
	print("Parsed!")
	await get_tree().process_frame
	var difficulties:Array = meta.get("_difficulties",[])
	
	if i == -1:
		for difficulty_index in range(difficulties.size()):
			if difficulty_index != 0: song = Song.new()
			if !file.file_exists(path.path_join(difficulties[difficulty_index])):
				print("map data file doesn't exist")
				$Finish/Error.text = "Map data file does not exist (%s)" % [difficulties[difficulty_index]]
				$Finish/Error.visible = true
				$Finish/Success.visible = false
				$Finish/Wait.visible = false
				$Finish/ok.visible = true
				$SelectDifficulty.visible = false
				$Finish.visible = true
				return
			var result:int = import_vmap_with_difficulty(difficulty_index)
			if result == 0:
				print("import failed")
				$Finish/Error.text = "Import failed (%s)" % [difficulties[difficulty_index]]
				$Finish/Error.visible = true
				$Finish/Success.visible = false
				$Finish/Wait.visible = false
				$Finish/ok.visible = true
				$SelectDifficulty.visible = false
				$Finish.visible = true
				return
			elif result == -1:
				return
		$Finish/Success.text = "All maps imported successfully!"
		$Finish/Error.visible = false
		$Finish/Success.visible = true
		$Finish/Wait.visible = false
		$Finish/ok.visible = true
		$SelectDifficulty.visible = false
		$Finish.visible = true
	else:
		if !file.file_exists(path.path_join(difficulties[i])):
			print("map data file doesn't exist")
			$Finish/Error.text = "Map data file does not exist (%s)" % [difficulties[i]]
			$Finish/Error.visible = true
			$Finish/Success.visible = false
			$Finish/Wait.visible = false
			$Finish/ok.visible = true
			$SelectDifficulty.visible = false
			$Finish.visible = true
			return
		var result:int = import_vmap_with_difficulty(i,false)
		if result == 0:
			print("import failed")
			$Finish/Error.text = "Import failed (%s)" % [difficulties[i]]
			$Finish/Error.visible = true
			$Finish/Success.visible = false
			$Finish/Wait.visible = false
			$Finish/ok.visible = true
			$SelectDifficulty.visible = false
			$Finish.visible = true
			return
		elif result == -1:
			return

func file_selected(files:PackedStringArray):
	if files.size() == 0: return
	match opening:
		FO_COVER:
			if !song: return
			var cover = Globals.imageLoader.load_file(files[0])
			if cover:
				song.cover = cover
				song.has_cover = true
				$Edit/Cover/T.texture = cover
				$Edit/Cover/C.disabled = false
				$Edit/Cover/C.button_pressed = true
				$TxtFile/H/E/Cover/T.texture = cover
				$TxtFile/H/E/Cover/C.disabled = false
				$TxtFile/H/E/Cover/C.button_pressed = true
		FO_SSPM:
			song = Song.new()
			song.load_from_sspm(files[0])
			$SelectType.visible = false
			populate_edit_screen()
			$Edit.visible = true
		FO_VZIP:
			$VulnusFile/Success.visible = false
			$VulnusFile/Error.visible = false
			
			print("Making temp dir")
			await get_tree().process_frame
			dir.open(Globals.p("user://"))
			if dir.dir_exists(Globals.p("user://temp")):
				print("Removing old temp dir")
				await get_tree().process_frame
				var found = await Globals.get_files_recursive(
					[Globals.p("user://temp")]
				)
				for p in found.files:
					var res:int = dir.remove(p)
					if res != OK:
						print("file delete returned error %s for file '%s'" % [res,p])
						$VulnusFile/Error.text = "failed to delete temp folder, file remove error %s" % [res]
						$VulnusFile/Error.visible = true
						return
				found.folders.invert()
				for p in found.folders:
					var res:int = dir.remove(p)
					if res != OK:
						print("file delete returned error %s for folder '%s'" % [res,p])
						$VulnusFile/Error.text = "failed to delete temp folder, folder remove error %s" % [res]
						$VulnusFile/Error.visible = true
						return
				var res:int = dir.remove(Globals.p("user://temp"))
				if res != OK:
					print("file delete returned error %s for temp dir" % [res])
					$VulnusFile/Error.text = "failed to delete temp folder, folder remove error %s" % [res]
					$VulnusFile/Error.visible = true
					return
			dir.make_dir(Globals.p("user://temp"))
			
			print("Extracting zip file...")
			await get_tree().process_frame
			
			var output = []
			var binarypath:String = ProjectSettings.get_setting("application/config/7zip_binary_path")
			if binarypath != "":
				if binarypath.begins_with("install_dir/"):
					binarypath = OS.get_executable_path().get_base_dir().path_join(binarypath.trim_prefix("install_dir/"))
				
				var outpath:String = ProjectSettings.globalize_path(Globals.p("user://temp"))
				var inpath:String = ProjectSettings.globalize_path(files[0])
				
				if inpath.ends_with(".vmap"):
					dir.rename(files[0], files[0].trim_suffix("vmap") + "zip")
				
				if OS.has_feature("Windows"): # Windows has different requirements for its file paths
					outpath = outpath.replace("\\","/")
					inpath = inpath.replace("\\","/")
				else:
					outpath = outpath.replace('"','\\"')
					inpath = inpath.replace('"','\\"')
				
				
				var args = [
					'x',
					'-bb0',
					'-y',
					'-bd',
					'-o"%s"' % [ProjectSettings.globalize_path(Globals.p("user://temp"))],
					'"%s"' % [files[0].replace("\\","/")],
					'*'
				]
				print(binarypath)
				var exit_code = OS.execute(binarypath, args, output, true, OS.has_feature("debug"))
				
				for o in output:
					print(o)
				
				if exit_code == -1:
					print("nonzero exit code of -1 indicateds engine error")
					$VulnusFile/Error.text = "engine error while extracting zip"
					$VulnusFile/Error.visible = true
					return
				elif exit_code != 0:
					print("nonzero exit code of %s" % [exit_code])
					$VulnusFile/Error.text = "error occurred while extracting zip (exit code %s)" % [exit_code]
					$VulnusFile/Error.visible = true
					return
			else:
				print("platform doesn't have a 7zip binary")
				$VulnusFile/Error.text = "zip imports currently aren't supported on this platform"
				$VulnusFile/Error.visible = true
				return
			
			path = Globals.p("user://temp")
			import_vulnus_folder()
		FO_VDIR:
			$VulnusFile/Success.visible = false
			$VulnusFile/Error.visible = false
			path = files[0]
			import_vulnus_folder()
		FO_TXT:
			song.initFile = files[0]
			file.open(files[0],File.READ)
			check_txt(file.get_as_text())
			file.close()
		FO_SONG:
#			if Rhythia.play_menu_music and !get_node("../MenuSong").playing:
#				get_node("../MenuSong").play()
#			$TxtFile/H/audio/player.stop()
#			$TxtFile/H/audio/preview/Title.text = "Preview"
			var stream = Globals.audioLoader.load_file(files[0])
			if stream == Globals.error_sound:
				$TxtFile/H/audio/preview.disabled = true
				$TxtFile/H/audio/preview.modulate = Color(0.5,0.5,0.5)
				$TxtFile/H/audio/Info.text = "Audio invalid or unsupported"
				$TxtFile/H/audio/Info.set("theme_override_colors/font_color",Color(1,0.5,0.5))
			else:
				song.musicFile = files[0]
				$TxtFile/H/audio/Info.text = files[0].get_file()
				$TxtFile/H/audio/Info.set("theme_override_colors/font_color",Color(0,1,0.5))
				$TxtFile/H/audio/preview.disabled = false
				$TxtFile/H/audio/preview.modulate = Color(1,1,1)
				if !(stream is AudioStreamWAV): stream.loop = true
				$TxtFile/H/audio/player.stream = stream
			check_txt_requirements()

func folder_selected(path:String):
	if path != "": file_selected(PackedStringArray([path]))

func edit_field(field:String,done:bool=false):
	if done:
		if !Input.is_action_just_pressed("ui_select"):
			match field:
				"name":
					if maptype == T_TXT:
						if $TxtFile/H/E/Info/SongName/T.text.length() != 0:
							song.name = $TxtFile/H/E/Info/SongName/T.text
							$TxtFile/H/E/Info/SongName/T.visible = false
							$TxtFile/H/E/Info/SongName.text = song.name
							if !txt_using_manual_id:
								song.id = generate_id(song.name,song.creator)
								$TxtFile/H/E/Info/Id.text = song.id
								$TxtFile/H/E/Info/Id/T.text = "auto"
							check_txt_requirements()
					else:
						if $Edit/Info/SongName/T.text.length() != 0:
							song.name = $Edit/Info/SongName/T.text
							$Edit/Info/SongName/T.visible = false
							$Edit/Info/SongName.text = song.name
						
				"mapper":
					if maptype == T_TXT:
						if $TxtFile/H/E/Info/Mapper/T.text.length() != 0:
							song.creator = $TxtFile/H/E/Info/Mapper/T.text
							$TxtFile/H/E/Info/Mapper/T.visible = false
							$TxtFile/H/E/Info/Mapper.text = tr("Mapper") +": %s" % song.creator
							if !txt_using_manual_id:
								song.id = generate_id(song.name,song.creator)
								$TxtFile/H/E/Info/Id.text = song.id
								$TxtFile/H/E/Info/Id/T.text = "auto"
							check_txt_requirements()
					else:
						if $Edit/Info/Mapper/T.text.length() != 0:
							song.creator = $Edit/Info/Mapper/T.text
							$Edit/Info/Mapper/T.visible = false
							$Edit/Info/Mapper.text = tr("Mapper") + ": %s" % song.creator
				"id":
					if maptype == T_TXT:
						var id = $TxtFile/H/E/Info/Id/T.text
						if id.length() == 0 or id.begins_with("_") or !("n" + id).replace("-","").is_valid_identifier():
							return
						elif song.id == id:
							$TxtFile/H/E/Info/Id/T.visible = false
							return
						elif id == "auto":
							$TxtFile/H/E/Info/Id/T.visible = false
							txt_using_manual_id = false
							check_txt_requirements()
							return
						else:
							txt_using_manual_id = true
							song.id = id
							$TxtFile/H/E/Info/Id/T.visible = false
							$TxtFile/H/E/Info/Id.text = song.id
							check_txt_requirements()
					else:
						var id = $Edit/Info/Id/T.text
						if id.length() == 0 or id.begins_with("_") or !("n" + id).replace("-","").is_valid_identifier():
							return
						else:
							song.id = id
							$Edit/Info/Id/T.visible = false
							$Edit/Info/Id.text = song.id
							if Rhythia.registry_song.idx_id.has(song.id):
								$Edit/done.disabled = true
								$Edit/done/Title.text = "ID in use"
							else:
								$Edit/done.disabled = false
								$Edit/done/Title.text = "Finish"
	else:
		match field:
			"name":
				if maptype == T_TXT:
					$TxtFile/H/E/Info/SongName/T.visible = true
					$TxtFile/H/E/Info/SongName/T.grab_focus()
					$TxtFile/H/E/Info/SongName/T.select_all()
				else:
					$Edit/Info/SongName/T.visible = true
					$Edit/Info/SongName/T.grab_focus()
					$Edit/Info/SongName/T.select_all()
			"mapper":
				if maptype == T_TXT:
					$TxtFile/H/E/Info/Mapper/T.visible = true
					$TxtFile/H/E/Info/Mapper/T.grab_focus()
					$TxtFile/H/E/Info/Mapper/T.select_all()
				else:
					$Edit/Info/Mapper/T.visible = true
					$Edit/Info/Mapper/T.grab_focus()
					$Edit/Info/Mapper/T.select_all()
			"id":
				if maptype == T_TXT:
					$TxtFile/H/E/Info/Id/T.visible = true
					$TxtFile/H/E/Info/Id/T.grab_focus()
					$TxtFile/H/E/Info/Id/T.select_all()
				else:
					$Edit/Info/Id/T.visible = true
					$Edit/Info/Id/T.grab_focus()
					$Edit/Info/Id/T.select_all()

func onopen():
	maptype = -1
	filetype = -1
	step = 0
	path = ""
	musicPath = ""
	dataPath = ""
	for n in get_children():
		if n is Control:
			n.visible = (n == $Title or n == $SelectType)
	
	$VulnusFile/Success.visible = false
	$VulnusFile/Error.visible = false
	$TxtFile/H/audio/preview/Title.text = "Preview"
	$TxtFile/H/audio/player.stop()
	$TxtFile/H/Temp.button_pressed = false
	
	visible = true

func difficulty_sel(i:int):
	if edit_pop or !song: return
	song.difficulty = i - 1
	if maptype == T_TXT:
		$TxtFile/H/E/Info/Difficulty.text = tr("Difficulty") + ": " + tr(Globals.difficulty_names[song.difficulty])
	else:
		$Edit/Info/Difficulty.text = tr("Difficulty") + ": " + tr(Globals.difficulty_names[song.difficulty])

func set_use_cover(v:bool):
	song.has_cover = v

func do_coversel():
	opening = FO_COVER
	Globals.file_sel.open_file(
		self,
		"file_selected",
		PackedStringArray(["*.png, *.jpg, *.jpeg, *.webp, *.bmp ; Image files"]),
		false,
		"~/Downloads"
	)

func finish_map():
#	$TxtFile/H/audio/player.stop()
	$Edit.visible = false
	$TxtFile.visible = false
	$Finish.visible = true
	$Finish/ok.visible = false
	$Finish/Error.visible = false
	$Finish/Success.visible = false
	$Finish/Wait.visible = true
	await get_tree().process_frame # Make sure the screen updates
	
	if (maptype == T_TXT and $TxtFile/H/Temp.button_pressed):
		song.discard_notes()
		song.read_notes()
		Rhythia.registry_song.check_and_remove_id(song.id)
		Rhythia.registry_song.add_item(song)
		$Finish/Wait.visible = false
		$Finish/Success.visible = true
		$Finish/ok.visible = true
	else:
		var result = song.convert_to_sspm()
	
		$Finish/Wait.visible = false
		if result == "Converted!":
			Rhythia.registry_song.check_and_remove_id(song.id)
			Rhythia.registry_song.add_sspm_map("user://maps/%s.sspm" % song.id)
			$Finish/Success.visible = true
		else:
			$Finish/Error.text = result
			$Finish/Error.visible = true
		$Finish/ok.visible = true
	var list = $"/root/Menu/Main/Maps/MapRegistry/S/VBoxContainer"
	list.prepare_songs()
	list.reload_to_current_page()

func back_to_menu():
	get_parent().black_fade_target = true
	await get_tree().create_timer(0.35).timeout
	Rhythia.conmgr_transit = null
	get_tree().change_scene_to_file("res://scenes/loaders/menuload.tscn")

func _ready():
	
	$SelectType/txt.connect("pressed", Callable(self, "select_type").bind(T_TXT))
	$SelectType/sspm.connect("pressed", Callable(self, "select_type").bind(T_SSPM))
	$SelectType/vulnus.connect("pressed", Callable(self, "select_type").bind(T_VULNUS))
	$SelectType/sspmr.connect("pressed", Callable(self, "select_type").bind(T_SSPMR))
	$SelectType/cancel.connect("pressed", Callable(self, "back_to_menu"))
	
	$VulnusFile/zip.connect("pressed", Callable(self, "sel_filetype").bind(F_ZIP))
	$VulnusFile/folder.connect("pressed", Callable(self, "sel_filetype").bind(F_DIR))
	
	$SelectDifficulty/S/V/All.connect("pressed", Callable(self, "vmap_difficulty_sel").bind(-1))
	
	$TxtFile/H/data/file.connect("pressed", Callable(self, "sel_filetype").bind(FO_TXT))
	$TxtFile/H/data/paste.connect("pressed", Callable(self, "do_txt_paste"))
	$TxtFile/H/data/text_done.connect("pressed", Callable(self, "end_txt_paste"))
	$TxtFile/H/audio/file.connect("pressed", Callable(self, "sel_filetype").bind(FO_SONG))
	$TxtFile/H/audio/preview.connect("pressed", Callable(self, "txt_song_preview"))
	
	$Edit/Cover/T/B.connect("pressed", Callable(self, "do_coversel"))
	$Edit/Cover/C.connect("toggled", Callable(self, "set_use_cover"))
	$Edit/Info/Difficulty/B.add_item("N/A",0)
	$Edit/Info/Difficulty/B.add_item("Easy",1)
	$Edit/Info/Difficulty/B.add_item("Medium",2)
	$Edit/Info/Difficulty/B.add_item("Hard",3)
	$Edit/Info/Difficulty/B.add_item("Logic?",4)
	$Edit/Info/Difficulty/B.add_item("Amogus",5)
	$Edit/Info/Difficulty/B.connect("item_selected", Callable(self, "difficulty_sel"))
	$Edit/Info/SongName/B.connect("pressed", Callable(self, "edit_field").bind("name"))
	$Edit/Info/SongName/T.connect("focus_exited", Callable(self, "edit_field").bind("name",true))
	$Edit/Info/Mapper/B.connect("pressed", Callable(self, "edit_field").bind("mapper"))
	$Edit/Info/Mapper/T.connect("focus_exited", Callable(self, "edit_field").bind("mapper",true))
	$Edit/Info/Id/B.connect("pressed", Callable(self, "edit_field").bind("id"))
	$Edit/Info/Id/T.connect("focus_exited", Callable(self, "edit_field").bind("id",true))
	
	$Edit/done.connect("pressed", Callable(self, "finish_map"))
	
	$TxtFile/H/E/Cover/T/B.connect("pressed", Callable(self, "do_coversel"))
	$TxtFile/H/E/Cover/C.connect("toggled", Callable(self, "set_use_cover"))
	$TxtFile/H/E/Info/Difficulty/B.add_item("N/A",0)
	$TxtFile/H/E/Info/Difficulty/B.add_item("Easy",1)
	$TxtFile/H/E/Info/Difficulty/B.add_item("Medium",2)
	$TxtFile/H/E/Info/Difficulty/B.add_item("Hard",3)
	$TxtFile/H/E/Info/Difficulty/B.add_item("Logic?",4)
	$TxtFile/H/E/Info/Difficulty/B.add_item("Amogus",5)
	$TxtFile/H/E/Info/Difficulty/B.connect("item_selected", Callable(self, "difficulty_sel"))
	$TxtFile/H/E/Info/SongName/B.connect("pressed", Callable(self, "edit_field").bind("name"))
	$TxtFile/H/E/Info/SongName/T.connect("focus_exited", Callable(self, "edit_field").bind("name",true))
	$TxtFile/H/E/Info/Mapper/B.connect("pressed", Callable(self, "edit_field").bind("mapper"))
	$TxtFile/H/E/Info/Mapper/T.connect("focus_exited", Callable(self, "edit_field").bind("mapper",true))
	$TxtFile/H/E/Info/Id/B.connect("pressed", Callable(self, "edit_field").bind("id"))
	$TxtFile/H/E/Info/Id/T.connect("focus_exited", Callable(self, "edit_field").bind("id",true))
	
	$TxtFile/done.connect("pressed", Callable(self, "finish_map"))
	
	$Edit/cancel.connect("pressed", Callable(self, "onopen"))
	$TxtFile/cancel.connect("pressed", Callable(self, "onopen"))
	$VulnusFile/cancel.connect("pressed", Callable(self, "onopen"))
	$SelectDifficulty/cancel.connect("pressed", Callable(self, "onopen"))
	$Finish/ok.connect("pressed", Callable(self, "onopen"))
	
#	call_deferred("add_child",openFile)
#	call_deferred("add_child",openFolder)
	call_deferred("onopen")

func _process(delta):
	if Input.is_action_just_pressed("ui_accept"):
		if $Edit/Info/Id/T.visible: edit_field("id",true)
		if $Edit/Info/SongName/T.visible: edit_field("name",true)
		if $Edit/Info/Mapper/T.visible: edit_field("mapper",true)
		if $TxtFile/H/E/Info/Id/T.visible: edit_field("id",true)
		if $TxtFile/H/E/Info/SongName/T.visible: edit_field("name",true)
		if $TxtFile/H/E/Info/Mapper/T.visible: edit_field("mapper",true)
