extends Node3D
class_name SongPlayerManager

signal note_hit
signal note_miss

var rawMapData:String
var notes:Array
var last_ms:float = 0
@onready var colors:Array = Rhythia.selected_colorset.colors
@onready var speed_multi = Globals.speed_multi[Rhythia.mod_speed_level]

var score:int = 0
var combo:int = 0
var combo_level:int = 1
var lvl_progress:int = 0
var song_has_failed:bool = false

@export var timer_fg_done: StyleBox

func comma_sep(number):
	var string = str(number)
	var mod = string.length() % 3
	var res = ""
	
	for i in range(0, string.length()):
		if i != 0 && i % 3 == mod:
			res += ","
		res += string[i]
	
	return res

func loadMapFile():
	var load_started_at := Time.get_ticks_msec()
	var map:Song = Rhythia.selected_song
	last_ms = map.last_ms# / $Spawn.speed_multi
#	print(last_ms)
	if map.should_reload_on_play:
		map.setup_from_file(map.initFile,map.musicFile)
	notes = map.read_notes()
	print("GAME_MAP_READ elapsed_ms=%d notes=%d" % [Time.get_ticks_msec() - load_started_at, notes.size()])
	if not notes.is_empty():
		last_ms = max(last_ms, float(notes[-1][2]))
	map.discard_notes()
	var file:File = File.new()
	var song:AudioStream = map.stream()
	
	
	
	$Spawn.spawn_notes(notes)
	print("GAME_MAP_PREPARED elapsed_ms=%d" % [Time.get_ticks_msec() - load_started_at])
	
	get_node("Spawn/Music").stream = song

@onready var head:Node3D = get_node("Avatar/Head")

var hits:float = 0
var misses:float = 0
var total_notes:float = 0
var energy:float = 6
var max_energy:float = 6
var energy_per_hit:float = 1
var max_combo:int = 0

func update_hud():
	$HUD.update_static_values()

var ending:bool = false
func end(end_type:int):
	if ending: return
	print("My god, what are you doing!?")
	ending = true
	if end_type == Globals.END_GIVEUP and Rhythia.record_replays and !Rhythia.replaying:
		Rhythia.replay.store_sig($Spawn.rms,Globals.RS_GIVEUP)
	if end_type != Globals.END_PASS:
		Rhythia.fail_asp.play()
	get_tree().paused = true
	if total_notes == 0: total_notes = 1
	update_hud()
	Rhythia.just_ended_song = true
	Rhythia.song_end_hits = hits
	Rhythia.song_end_misses = misses
	Rhythia.song_end_total_notes = total_notes
	Rhythia.song_end_position = min($Spawn.ms,last_ms)
	Rhythia.song_end_length = last_ms
	Rhythia.song_end_type = end_type
	Rhythia.song_end_combo = max_combo
	print("song max combo: ", max_combo)
	
	if Rhythia.record_replays and !Rhythia.replaying:
		Rhythia.replay.end_recording()
	
	if Rhythia.queue_active and end_type == Globals.END_PASS:
		if Rhythia.do_pb_check_and_set():
			Globals.notify(Globals.NOTIFY_SUCCEED,"new best!")
		var next = Rhythia.get_next()
		$Spawn.ms_offset += max($Spawn.ms - (Rhythia.start_offset - (3000 * $Spawn.speed_multi)), 0)
		if Rhythia.queue_active and next:
			$Spawn.ms = Rhythia.start_offset - (3000 * $Spawn.speed_multi)
			Rhythia.select_song(next)
			$HUD.set_song_name(Rhythia.selected_song.name)
			Rhythia.update_rpc_song()
			if Rhythia.record_replays and !Rhythia.replaying:
				Rhythia.replay = Replay.new()
				Rhythia.replay.start_recording(Rhythia.selected_song)
			
			$Spawn.notes_loaded = false
			$Spawn.chaos_rng = RandomNumberGenerator.new()
			$Spawn.earthquake_rng = RandomNumberGenerator.new()
			$Spawn.chaos_rng.seed = hash(Rhythia.selected_song.id)
			$Spawn.earthquake_rng.seed = hash(Rhythia.selected_song.id)
			$Spawn.music_started = false
			$Spawn.out_of_notes = false
			$Spawn.note_count = 0
			
			$Spawn.prev_ms = (Rhythia.start_offset - (3000 * $Spawn.speed_multi))
			$Spawn.next_ms = 0
			get_tree().paused = false
			$Spawn.emit_signal("ms_change",$Spawn.ms)
			loadMapFile()
			ending = false
			return
	elif Rhythia.restart_on_death and end_type == Globals.END_FAIL and !Rhythia.replaying:
		if Rhythia.do_pb_check_and_set():
			print("Logging PB, restarting death")
		"""
		Change this func and one in EndInfo.gd to display PB when giving up with restart_on_death (since its the only escape outside of passing)
		It saves the PB yet it shows you failed until you reload the song in the menu
		My poor brain is fuming with this code lmao

		- helmeto
		"""
		
		get_tree().change_scene_to_file("res://scenes/song.tscn")
	else:
		black_fade_target = true
		await get_tree().create_timer(0.35).timeout
		get_tree().change_scene_to_file("res://scenes/loaders/menuload.tscn")

func update_timer(ms:float,canSkip:bool=false):
	var qms = ms + $Spawn.ms_offset
	var lms = last_ms
	
	if Rhythia.queue_active:
		lms = Rhythia.queue_end_length + (3000 * (Rhythia.song_queue.size() - 1))
	
	var s = clamp(floor(qms/1000),0,lms/1000)
	var m = floor(s / 60)
	var rs = fmod(s,60)
	
	var ls = floor(lms/1000)
	var lm = floor(ls / 60)
	var lrs = fmod(ls,60)
	
	$HUD.update_timer(ms,canSkip)
	
	if Rhythia.queue_active:
		if ms >= last_ms + $Spawn.hit_window:
			get_node("Spawn/Music").volume_db -= (17 * get_process_delta_time())
		else:
			get_node("Spawn/Music").volume_db = Rhythia.music_volume_db
	
	if ms >= last_ms + $Spawn.hit_window:
		if Rhythia.queue_active and ms >= last_ms + max($Spawn.hit_window,3000):
			get_node("Spawn/Music").stop()
			end(Globals.END_PASS)
		elif !Rhythia.queue_active and !get_node("Spawn/Music").playing:
			end(Globals.END_PASS)



var loaded = false

var giving_up:float = 0
var black_fade_target:bool = true
var black_fade:float = 1
var passed:bool = false

func _process(delta):
	
	if !Rhythia.queue_active and $Spawn.ms > last_ms:
		passed = true
			
		head.get_node("EyeL").visible = false
		head.get_node("HappyL").visible = true
			
		head.get_node("EyeR").visible = false
		head.get_node("HappyR").visible = true
		
	if passed:
		$Avatar/ArmR.position.y += (1 - $Avatar/ArmR.position.y) * 0.01
	
	if !ending:
		if Input.is_action_pressed("give_up"):
			giving_up += delta/0.6
			if giving_up >= 1:
				if !Rhythia.queue_active and $Spawn.ms > last_ms: end(Globals.END_PASS)
				else: end(Globals.END_GIVEUP)
		else:
			giving_up = 0
	
	if Rhythia.replaying and Input.is_action_just_pressed("pause"):
		get_tree().paused = !get_tree().paused
	
	if get_tree().paused:
		$Spawn.last_usec = Time.get_ticks_usec()
	
	
	if black_fade_target && black_fade != 1:
		black_fade = min(black_fade + (delta/0.3),1)
		$BlackFade.color = Color(0,0,0,black_fade)
	elif !black_fade_target && black_fade != 0:
		black_fade = max(black_fade - (delta/0.75),0)
		$BlackFade.color = Color(0,0,0,black_fade)
	$BlackFade.visible = (black_fade != 0)
	

func linstep(a:float,b:float,x:float):
	if a == b: return float(x >= a)
	return clamp(abs((x - a) / (b - a)),0,1)

func get_point_amt() -> int:
	var spd = clamp(((speed_multi - 1) * 1.5) + 1, 0, 1.9)
	
	var hitbox_diff = Rhythia.note_hitbox_size - 1.140
	var hbo = clamp(linstep(1.140,0,hitbox_diff), 0, 1)
	
	var hitwin_diff = Rhythia.note_hitbox_size - 55
	var hwi = clamp(linstep(55,0,hitwin_diff), 0, 1)
	
	var mod = 1
	
	return int(floor((50 * spd * min(hbo,hwi) * mod) + 0.5) * combo_level)


func hit(col):
	emit_signal("note_hit",col)
	hits += 1
	total_notes += 1
	if !Rhythia.mod_no_regen: energy = clamp(energy+energy_per_hit,0,max_energy)
	combo += 1

	if combo > max_combo: max_combo = combo

	var points = get_point_amt()
	if combo_level != 8:
		lvl_progress += 1
	if combo_level != 8 and lvl_progress == 10:
		lvl_progress = 0
		combo_level += 1
		if combo_level == 8: lvl_progress = 10
	update_hud()
	
	if Rhythia.hit_fov:
		if Rhythia.hit_fov_additive:
			$"../Camera3D".fov += Rhythia.hit_fov_amplifier
		elif Rhythia.hit_fov_exponential:
			$"../Camera3D".fov *= Rhythia.hit_fov_amplifier
		else:
			$"../Camera3D".fov = Rhythia.get("fov") - Rhythia.hit_fov_amplifier
	
	score += points
	return points

func dense_hits(count:int, col:Color) -> void:
	if count <= 0:
		return
	emit_signal("note_hit",col)
	hits += count
	total_notes += count
	if !Rhythia.mod_no_regen:
		energy = clamp(energy + energy_per_hit * count, 0, max_energy)
	var remaining := count
	while remaining > 0:
		var step:int = remaining if combo_level == 8 else min(remaining, 10 - lvl_progress)
		score += get_point_amt() * step
		combo += step
		remaining -= step
		if combo_level != 8:
			lvl_progress += step
			if lvl_progress >= 10:
				lvl_progress = 0
				combo_level += 1
				if combo_level == 8:
					lvl_progress = 10
	max_combo = max(max_combo, combo)
	update_hud()

func miss(col):
	emit_signal("note_miss",col)
	misses += 1
	total_notes += 1
	energy = clamp(energy-1,0,max_energy)
	combo = 0
	lvl_progress = 0
	if combo_level != 1: combo_level -= 1
	update_hud()
	if energy == 0: 
		if Rhythia.mod_nofail:
			if not song_has_failed:
				song_has_failed = true
				Rhythia.fail_asp.play()
		else:
			end(Globals.END_FAIL)

func dense_misses(count:int, col:Color) -> void:
	if count <= 0:
		return
	emit_signal("note_miss",col)
	misses += count
	total_notes += count
	energy = clamp(energy - count, 0, max_energy)
	combo = 0
	lvl_progress = 0
	if combo_level != 1:
		combo_level -= 1
	update_hud()
	if energy == 0:
		if Rhythia.mod_nofail:
			if not song_has_failed:
				song_has_failed = true
				Rhythia.fail_asp.play()
		else:
			end(Globals.END_FAIL)


func _ready():
	Rhythia.song_end_pause_count = 0
	Rhythia.song_end_misses = 0
	get_tree().paused = true
	get_node("Spawn/Music").volume_db = Rhythia.music_volume_db
	if Rhythia.mod_sudden_death:
		max_energy = 1
	elif Rhythia.health_model == Globals.HP_OLD:
		energy_per_hit = 1
		if Rhythia.mod_extra_energy: max_energy = 10
		else: max_energy = 6
	elif Rhythia.health_model == Globals.HP_SOUNDSPACE:
		energy_per_hit = 0.5
		if Rhythia.mod_extra_energy: max_energy = 8
		else: max_energy = 5
	
	energy = max_energy
#	var space = Rhythia.loaded_world
	var spinst = Rhythia.loaded_world.instantiate()
	get_parent().call_deferred("add_child",spinst)
	spinst.name = "Space"
#	call_deferred("raise")
	$BlackFade.visible = true
	$BlackFade.color = Color(0,0,0,black_fade)
	get_tree().paused = false
	$Spawn.connect("timer_update", Callable(self, "update_timer"))
#	$Spawn.connect("hit",self,"hit")
	$Spawn.connect("miss", Callable(self, "miss"))
	loadMapFile()
	
	
	Rhythia.update_rpc_song()
	
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	black_fade_target = false
	$ForceMatLoad.visible = false
	$Spawn.active = true
