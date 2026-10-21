extends GridContainer

signal search_updated

var songs:Array = Rhythia.registry_song.get_items()
var btns:Array = []

var search_text:String = ""
var author_search_text:String = ""
var difficulty_filter:Array = Rhythia.last_difficulty_filter
var show_broken_maps:bool = false
var show_online_maps:bool = true
var flip_display:bool = false
var flip_name:bool = false

var page = 0

var favorite:Array = []
var easy:Array = []
var medium:Array = []
var hard:Array = []
var logic:Array = []
var amogus:Array = []
var unknown:Array = []

var disp:Array = []

var is_ready:bool = false

func is_fav(s:Song): return favorite.has(s)
func search_matches(s:Song):
	return (
		difficulty_filter.has(s.difficulty) and
		(!s.is_online or show_online_maps) and
		(!s.is_broken or show_broken_maps) and
		(search_text == "" or s.name.to_lower().find(search_text.to_lower()) != -1) and
		(author_search_text == "" or s.creator.to_lower().find(author_search_text.to_lower()) != -1)
	)

var has_been_pressed = false
func play_song():
	if !Rhythia.selected_song: return
	if has_been_pressed: return
	has_been_pressed = true
	get_viewport().get_node("Menu").black_fade_target = true
	await get_tree().create_timer(0.35).timeout
	get_tree().change_scene_to_file("res://scenes/loaders/songload.tscn")

var pt = 1
func on_pressed(i):
	$Press.play()
	var s:Song = disp[i]
	if s != Rhythia.selected_song:
		Rhythia.select_song(s)
	else:
		print(pt)
		if pt < 0.25:
			play_song()
	pt = 0
	switch_to_play_screen()

var auto_switch_to_play:bool = true
func switch_to_play_screen():
	if !auto_switch_to_play: return
	if Rhythia.menu_target == "res://scenes/menu/menu.tscn": return
	get_viewport().get_node("Menu/Main/MapRegistry").visible = false
	get_viewport().get_node("Menu/Main/Results").visible = true
	get_viewport().get_node("Menu/Sidebar/L/Results").button_pressed = true

var was_maximized = (get_window().mode == Window.MODE_MAXIMIZED)
var was_fullscreen = ((get_window().mode == Window.MODE_EXCLUSIVE_FULLSCREEN) or (get_window().mode == Window.MODE_FULLSCREEN))
func _process(delta):
	pt += delta
	if (get_window().mode == Window.MODE_MAXIMIZED) != was_maximized or ((get_window().mode == Window.MODE_EXCLUSIVE_FULLSCREEN) or (get_window().mode == Window.MODE_FULLSCREEN)) != was_fullscreen:
		was_maximized = (get_window().mode == Window.MODE_MAXIMIZED)
		was_fullscreen = ((get_window().mode == Window.MODE_EXCLUSIVE_FULLSCREEN) or (get_window().mode == Window.MODE_FULLSCREEN))
		handle_window_resize()
#		yield(get_tree().create_timer(0.1),"timeout")
#		load_pg()

func select_random():
	if disp.size() == 0: return
	on_pressed(randi()%disp.size())
	for b in btns:
		if b.song == Rhythia.selected_song: b.get_node("Select").button_pressed = true
		else: b.get_node("Select").button_pressed = false
	switch_to_play_screen()

var page_size = Vector2(-1,-1)
func load_pg(is_resize:bool=false):
	
	var col = max(floor((get_parent().size.x-124)/132),1)
	if columns != col: columns = col
	var spp = max(col*floor((get_parent().size.y-74)/132),1)
	if is_resize and Vector2(col,spp) == page_size: return
	else: page_size = Vector2(col,spp)
	
	for n in btns: n.queue_free()
	btns.clear()
	if floor(float(disp.size())/spp) < page:
		print("page too far! max: %s, actual: %s" % [floor(float(disp.size())/spp), page])
		page = floor(float(disp.size())/spp)
	for i in range(page*spp,((page+1)*spp)):
		if i < disp.size():
			var map:Song = disp[i]
			var btn:Panel
			match map.difficulty:
				Globals.DIFF_EASY: btn = $EASY.duplicate()
				Globals.DIFF_MEDIUM: btn = $MEDIUM.duplicate()
				Globals.DIFF_HARD: btn = $HARD.duplicate()
				Globals.DIFF_LOGIC: btn = $LOGIC.duplicate()
				Globals.DIFF_AMOGUS: btn = $AMOGUS.duplicate()
				_: btn = $NODIF.duplicate()
			btn.get_node("Label").visible = false
			if map.has_cover:
				btn.get_node("Cover").visible = true
				btn.get_node("Cover").texture = map.cover
			else:
				btn.get_node("Name").visible = true
				btn.get_node("Name").text = map.name
			btns.append(btn)
			btn.song = map
			if map.warning != "" || map.is_broken:
				if map.is_broken: btn.get_node("Name").modulate = Color(1,0.4,0.4)
				else: btn.get_node("Name").modulate = Color(1,1,0.2)
			var rbtn:Button = btn.get_node("Select")
			if is_fav(map): btn.get_node("F").visible = true
			btn.get_node("Cloud").visible = map.is_online
			rbtn.disabled = false
			rbtn.connect("pressed", Callable(self, "on_pressed").bind(i))
			if map == Rhythia.selected_song:
				btn.get_node("Select").button_pressed = true
			add_child(btn)
			btn.visible = true
			
	get_parent().get_node("P").position.x = (col*132) + 66
	get_parent().get_node("P").size.y = ((spp/col)*132)+12
	get_parent().get_node("M").size.y = ((spp/col)*132)+12

func append_filtering_favorites(to:Array,from:Array):
	for s in from:
		if search_matches(s) and !is_fav(s):
			to.append(s)


func build_list():
	disp = []
	favorite = []
	for id in Rhythia.favorite_songs:
		var s = Rhythia.registry_song.get_item(id)
		if s and search_matches(s) and Rhythia.is_favorite(id):
			favorite.append(s)
	favorite.sort_custom(Callable(self, "sortsong"))
	disp.append_array(favorite)
	if flip_display:
		append_filtering_favorites(disp,amogus)
		append_filtering_favorites(disp,logic)
		append_filtering_favorites(disp,hard)
		append_filtering_favorites(disp,medium)
		append_filtering_favorites(disp,easy)
		append_filtering_favorites(disp,unknown)
	else:
		append_filtering_favorites(disp,easy)
		append_filtering_favorites(disp,medium)
		append_filtering_favorites(disp,hard)
		append_filtering_favorites(disp,logic)
		append_filtering_favorites(disp,amogus)
		append_filtering_favorites(disp,unknown)

func reload_to_current_page(_a=null):
	build_list()
	if is_ready: Rhythia.last_page_num = page
	load_pg()

func update_search_text(txt:String):
	search_text = txt
	if is_ready: reload_to_current_page()
	emit_signal("search_updated")

func update_author_search_text(txt:String):
	author_search_text = txt
	if is_ready: reload_to_current_page()
	emit_signal("search_updated")

func update_search_dfil(dfil:Array):
	difficulty_filter = dfil
	Rhythia.last_difficulty_filter = dfil
	if is_ready: reload_to_current_page()
	emit_signal("search_updated")

func update_search_showbroken(show:bool):
	show_broken_maps = show
	if is_ready: reload_to_current_page()

func update_search_showonline(show:bool):
	show_online_maps = show
	if is_ready: reload_to_current_page()

func update_search_flipped(flip:bool):
	flip_display = flip
	if is_ready: reload_to_current_page()

func update_search_flip_name(flip:bool):
	flip_name = flip
	easy.sort_custom(Callable(self, "sortsongsimple"))
	medium.sort_custom(Callable(self, "sortsongsimple"))
	hard.sort_custom(Callable(self, "sortsongsimple"))
	logic.sort_custom(Callable(self, "sortsongsimple"))
	amogus.sort_custom(Callable(self, "sortsongsimple"))
	if is_ready: reload_to_current_page()

func sortab(a, b): return a < b

func sortsongsimple(a:Song, b:Song):
	if flip_name:
		if a.name != b.name: return a.name.to_lower() > b.name.to_lower()
		else: return a.id > b.id
	else:
		if a.name != b.name: return a.name.to_lower() < b.name.to_lower()
		else: return a.id < b.id

func sortsong(a:Song, b:Song):
	var ad = a.difficulty
	var bd = b.difficulty
	if ad == -1: ad = 255
	if bd == -1: bd = 255
	if ad != bd:
		if flip_display: return ad > bd
		else: return ad < bd
	else: return sortsongsimple(a,b)

func prepare_songs():
	for i in range(songs.size()):
		var map:Song = songs[i]
		var add_to:Array
		match map.difficulty:
			Globals.DIFF_EASY: add_to = easy
			Globals.DIFF_MEDIUM: add_to = medium
			Globals.DIFF_HARD: add_to = hard
			Globals.DIFF_LOGIC: add_to = logic
			Globals.DIFF_AMOGUS: add_to = amogus
			_: add_to = unknown
		add_to.append(map)
#	Rhythia.connect("selected_song_changed",self,"on_map_selected")
	easy.sort_custom(Callable(self, "sortsongsimple"))
	medium.sort_custom(Callable(self, "sortsongsimple"))
	hard.sort_custom(Callable(self, "sortsongsimple"))
	logic.sort_custom(Callable(self, "sortsongsimple"))
	amogus.sort_custom(Callable(self, "sortsongsimple"))

func pg(dir:int):
	$Press.play()
	page = clamp(page + dir, 0, floor(songs.size()))
	Rhythia.last_page_num = page
	load_pg()

#var last_size = OS.window_size
#func _process(delta):
#	if OS.window_size != last_size:
#		last_size = OS.window_size
#		load_pg()

func _input(ev:InputEvent):
	if is_visible_in_tree() and ev is InputEventMouseButton and ev.is_pressed():
		if ev.button_index == MOUSE_BUTTON_WHEEL_UP:
			pg(-1)
		elif ev.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			pg(1)

func handle_window_resize():
	if is_ready: load_pg(true)

func firstload():
	get_parent().get_node("P").connect("pressed", Callable(self, "pg").bind(1))
	get_parent().get_node("M").connect("pressed", Callable(self, "pg").bind(-1))
	get_parent().get_node("Random").connect("pressed", Callable(self, "select_random"))
	page = Rhythia.last_page_num
	prepare_songs()
	reload_to_current_page()
	is_ready = true
	Rhythia.connect("favorite_songs_changed", Callable(self, "reload_to_current_page"))
	Rhythia.connect("download_done", Callable(self, "reload_to_current_page"))
	get_viewport().connect("size_changed", Callable(self, "handle_window_resize"))
	Rhythia.emit_signal("map_list_ready")

func _ready():
	randomize()
	if !visible: return
	$EASY.visible = false
	$MEDIUM.visible = false
	$HARD.visible = false
	$LOGIC.visible = false
	$AMOGUS.visible = false
	$NODIF.visible = false
	call_deferred("firstload")
