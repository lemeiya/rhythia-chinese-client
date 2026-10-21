extends Panel

const CommunityPanelScene = preload("res://scripts/ui/menu/CommunityPanel.gd")

var open:bool = false
var open_amt:float = 1

@onready var pages:Array = [
#	get_node("../Main/Results"),
	get_node("../Main/Maps"),
	get_node("../Main/Settings"),
	get_node("../Main/Credits"),
	get_node("../Main/Content"),
	get_node("../Main/Language"),
	get_node("../Main/RhythiaRewrite")
]
@onready var buttons:Array = [
	$L/Results,
#	$L/MapSelect,
	$L/Settings,
	$L/Credits,
	$L/ContentMgr,
	$L/Language,
	$L/RhythiaRewrite
]
var use_ver_b:Array = [
	false,
#	false,
	true,
	false,
	false,
	false,
	false
]
var hide_ver:Array = [
	false,
#	false,
	false,
	true,
	false,
	false,
	false
]
@onready var smm_visibility:Dictionary = {
	$L/Results: true,
#	$L/MapSelect: true,
	$L/Settings: true,
	$L/Credits: true,
	$L/ContentMgr: true,
	$L/Language: false,
	$L/StartVR: false,
	$L/OldMenu: false,
	$L/Quit: true,
	$L/RhythiaRewrite: true
}

func press(bi:int,q:bool=false):
	if !q: get_node("../Press").play()
	for i in range(pages.size()):
		pages[i].visible = i == bi
		buttons[i].button_pressed = i == bi
	await get_tree().process_frame

	get_node("../VersionNumber").visible = !use_ver_b[bi]
	get_node("../VersionNumberB").visible = use_ver_b[bi]
	if (hide_ver[bi]):
		get_node("../VersionNumber").self_modulate = Color(1,1,1,0)
	else:
		get_node("../VersionNumber").self_modulate = Color(1,1,1,1)
#	open = false
#	get_node("Click").visible = !open
#	get_node("../SidebarClick").visible = open

func to_old_menu():
	get_node("../Press").play()
	get_viewport().get_node("Menu").black_fade_target = true
	if Input.is_key_pressed(KEY_C):
		if !Rhythia.selected_song:
			Globals.notify(Globals.NOTIFY_WARN,"No selected song","Automatically selecting a song")
			Rhythia.select_song(Rhythia.registry_song.items[0])
		Rhythia.menu_target = "res://scripts/cursordance/dancetest.tscn"
	else: Rhythia.menu_target = "res://scenes/menu/menu.tscn"
	await get_tree().create_timer(0.35).timeout
	get_tree().change_scene_to_file("res://scenes/loaders/menuload.tscn")

func to_vr():
	get_node("../Press").play()
	get_viewport().get_node("Menu").black_fade_target = true
	await get_tree().create_timer(0.35).timeout
	Rhythia.start_vr()

func quit():
	get_node("../Press").play()
	get_viewport().get_node("Menu").black_fade_target = true
	await get_tree().create_timer(0.35).timeout
	get_tree().quit()

func _ready():
	_install_community_page()
	for i in range(buttons.size()):
		buttons[i].connect("pressed", Callable(self, "press").bind(i))

	press(0,true)
	$Click.connect("mouse_entered", Callable(self, "_on_Sidebar").bind(true))
	$L.connect("mouse_entered", Callable(self, "_on_Sidebar").bind(true))
	connect("mouse_exited", Callable(self, "_on_Sidebar").bind(false))
	$L/OldMenu.connect("pressed", Callable(self, "to_old_menu"))
	$L/StartVR.connect("pressed", Callable(self, "to_vr"))
	$L/Quit.connect("pressed", Callable(self, "quit"))

	$L/ContentMgr.visible = not Rhythia.vr
#	$L/StartVR.visible = Rhythia.vr_available and not Rhythia.vr
	if Rhythia.vr or !OS.has_feature("pc"):
		$L/Quit/Label.text = "Quit to Home"

	if Rhythia.single_map_mode:
		for n in $L.get_children():
			n.visible = smm_visibility.get(n,false)

func _install_community_page():
	var page = CommunityPanelScene.new()
	page.name = "Community"
	page.visible = false
	get_node("../Main").add_child(page)
	page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var button:Button = $L/Language.duplicate()
	button.name = "Community"
	button.visible = true
	button.get_node("Label").text = "中文社区"
	button.get_node("Tex").texture = load("res://assets/images/ui/home.png")
	$L.add_child(button)
	$L.move_child(button, $L/Language.get_index())

	pages.append(page)
	buttons.append(button)
	use_ver_b.append(false)
	hide_ver.append(false)
	smm_visibility[button] = false

func _process(delta:float):
	if open and not Rect2(get_global_rect()).has_point(get_global_mouse_position()): # mouse_exited is not reliable
		_on_Sidebar(false)

	if open == true and open_amt != 1:
		open_amt = min(open_amt + max((1 - open_amt) * delta * 14, 0.05*delta),1)
#		if open_amt > 0.99: open_amt = 1
	elif open == false and open_amt != 0:
		open_amt = max(open_amt + min((0 - open_amt) * delta * 12, -0.05*delta),0)
#		if open_amt < 0.01: open_amt = 0

	size.x = 60 + (180 * open_amt)

func _input(ev):
	if (ev is InputEventScreenTouch or ev is InputEventMouseButton):
		if ev.pressed != true: return
		open = ev.position.x < size.x and ev.position.y < size.y
		await get_tree().process_frame
		get_node("Click").visible = !open
		get_node("../SidebarClick").visible = open

	if Input.is_action_just_pressed("ui_quicksettings"):
		press(1)

	if Input.is_action_just_pressed("menu_quickbar"): # uuhhh no, mouse checks won't work with this
		open = true
		get_node("Click").visible = !open

func _on_Sidebar(isEntered: bool):
	open = isEntered
	get_node("Click").visible = !open
	get_node("../SidebarClick").visible = open
