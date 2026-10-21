extends Node3D

var running = false
var panning = false
var ifading = false
var fading = false
var can_skip = false
var can_skip2 = false
var date = Time.get_datetime_dict_from_system()

func _ready():
	# Let desktop users skip immediately, including during the opening fade-in.
	can_skip = true
	
	# fix hands
	$Avatar/ArmL/Pointer.position = Vector3(0,0,0)
	$Avatar/ArmR/Mesh.position = Vector3(0,0,0)
	
	# lacunella
	if Rhythia.is_lacunella_enabled() and !((date.month == 6 and date.day == 07) or (date.month == 6 and date.day == 19)):
		$Avatar/Head/CubellaHair.visible = true

	# for max
	if Rhythia.memory_lacu() or ((date.month == 6 and date.day == 07) or (date.month == 6 and date.day == 19)):
		$Avatar/Head/CubellaHair.visible = true
		$Avatar/Head/CubellaHair/Hair.visible = false
		$Avatar/Head/CubellaHair/Ears.visible = false
		$Avatar/Head/CubellaHair/ElfL.visible = false
		$Avatar/Head/CubellaHair/ElfR.visible = false
		$Avatar/Head/CubellaHair/Hair_dya.visible = true
		$Avatar/Head/CubellaHair/Ears_dya.visible = true
	
	if OS.has_feature("Android"):
		$Skip.text = "Tap to skip"
	$ColorRect.modulate.a = 1
#	OS.window_fullscreen = true
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	await get_tree().create_timer(4).timeout
	running = true
	$Avatar/Animations.play("Float")
	$Avatar/Animations.speed_scale = 1
	$Camera2.rotation_degrees.y = 0
	await get_tree().create_timer(1).timeout
	$AudioStreamPlayer.play()
	can_skip = true
	await get_tree().create_timer(6.5).timeout
	$Camera3D.current = false
	$Camera2.current = true
	panning = true
	can_skip2 = true
	await get_tree().create_timer(14).timeout
	fading = true
	await get_tree().create_timer(4).timeout
	get_tree().change_scene_to_file("res://scenes/init.tscn")

func _is_skip_event(event:InputEvent) -> bool:
	var desktop_skip:bool = event.is_action_pressed("pause")
	if event is InputEventKey:
		desktop_skip = desktop_skip or event.keycode == KEY_ESCAPE or event.physical_keycode == KEY_ESCAPE

	var mobile_skip:bool = false
	if OS.has_feature("Android") and event is InputEventScreenTouch:
		mobile_skip = event.pressed
	return desktop_skip or mobile_skip

func _input(event:InputEvent):
	if not can_skip:
		return

	if _is_skip_event(event):
		can_skip = false
		get_viewport().set_input_as_handled()
		get_tree().change_scene_to_file("res://scenes/init.tscn")

func _process(delta):
	$Sprite3D.rotation_degrees.z += 16 * delta
	$Sprite3D2.rotation_degrees.z += 8 * delta
	$Sprite3D3.rotation_degrees.z += 4 * delta
	
	if running and not fading:
		$ColorRect.modulate.a += (0 - $ColorRect.modulate.a) * 0.4 * delta
	if panning:
		$Camera2.position.y += (12 - $Camera2.position.y) * 0.3 * delta
		$Camera2.rotation_degrees.y += (180 - $Camera2.rotation_degrees.y) * 0.4 * delta
	if fading:
		$ColorRect.modulate.a += (1 - $ColorRect.modulate.a) * 2 * delta
		$Skip.modulate.a += (0 - $Skip.modulate.a) * 2 * delta
	if can_skip2 and not fading:
		$Skip.modulate.a += (0.5 - $Skip.modulate.a) * 1 * delta
