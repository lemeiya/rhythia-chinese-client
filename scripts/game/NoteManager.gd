extends Node3D
class_name NoteManager

signal ms_change
signal timer_update
signal hit
signal miss

@export var note_solid_mat: Material
@export var note_transparent_mat: Material
@export var asq_mat: Material

var approach_rate:float = Rhythia.get("approach_rate")
var hit_window:float = Rhythia.get("hitwindow_ms")
var speed_multi:float = Globals.speed_multi[Rhythia.mod_speed_level]
var ms:float = Rhythia.start_offset - (3000 * speed_multi) # make waiting time shorter on lower speeds
var notes_loaded:bool = false
var hitsync_ensured:bool = false

var active:bool = false

var noteNodes:Array = []
var noteCache:Array = []
var noteQueue:Array = []
var colors:Array = Rhythia.selected_colorset.colors
var hitEffect:Node3D = load(Rhythia.selected_hit_effect.path).instantiate()
var missEffect:Node3D = load(Rhythia.selected_miss_effect.path).instantiate()
var scoreEffect:Node3D = load("res://assets/notefx/score/score.tscn").instantiate()
var hit_id:String = Rhythia.selected_hit_effect.id
var miss_id:String = Rhythia.selected_miss_effect.id
var chaos_rng:RandomNumberGenerator = RandomNumberGenerator.new()
var earthquake_rng:RandomNumberGenerator = RandomNumberGenerator.new()

var matcache_hit:Dictionary = {}
var matcache_miss:Dictionary = {}

const base_position = Vector3(-1,1,0)

var prev_ms:float = -100000

var next_ms:float = 0

var last_cursor_position:Vector3 = Vector3(-1,1,0)


# new mmi note stuff
var fade_in_enabled:bool = true
var fade_in_start:float = 8
var fade_in_end:float = 6

var fade_out_enabled:bool = false
var fade_out_start:float = 3
var fade_out_end:float = 1

var fade_out_base:float = 1


var notes:PackedFloat32Array = PackedFloat32Array()
var note_positions:PackedVector2Array = PackedVector2Array()
var note_states:PackedByteArray = PackedByteArray()
var note_chaos_offsets:PackedVector2Array = PackedVector2Array()
var note_index_offset:int = 0
var dense_rendering:bool = false
var dense_loaded_until:int = 0
var dense_approach_speed:float = 0.0
var dense_future_ms:float = 0.0
var dense_time_origin_ms:float = 0.0
var dense_peak_window_count:int = 0
const DENSE_REBASE_INTERVAL_MS:float = 1000.0
var current_note:int = 0
var note_transform_scale:Vector3
var note_image:Texture2D

var grid_pushback:float = 0.1 # default 0.1
var pushback_defaults:Dictionary = {
	"do_pushback": 4,
	"never": 0.1
}

func linstep(a:float,b:float,x:float):
	if a == b: return float(x >= a)
	return clamp(((x - a) / (b - a)),0,1)

func note_color(i:int) -> Color:
	return colors[(i + note_index_offset) % colors.size()]

func note_transform(i:int, z:float = 4.0) -> Transform3D:
	var nt := Transform3D().scaled(note_transform_scale)
	nt.origin = Vector3(note_positions[i].x, note_positions[i].y, z)
	return nt

func create_note_instance_material(distance_fade:bool) -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = """shader_type spatial;
render_mode blend_mix, cull_back, depth_prepass_alpha, unshaded;

uniform bool distance_fade_enabled = false;
uniform float fade_start = 40.0;
uniform float fade_end = 20.0;
uniform bool use_image = false;
uniform sampler2D note_texture : source_color, filter_linear;

varying vec4 note_color;
varying float distance_fade;

void vertex() {
	note_color = INSTANCE_CUSTOM;
	float current_dist = max(-(MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).z, 0.0);
	float fade_range = max(fade_start - fade_end, 0.001);
	distance_fade = distance_fade_enabled ? pow(clamp((fade_start - current_dist) / fade_range, 0.0, 1.0), 1.3) : 1.0;
}

void fragment() {
	vec4 image_color = use_image ? texture(note_texture, UV) : vec4(1.0);
	ALBEDO = note_color.rgb * image_color.rgb;
	ALPHA = note_color.a * distance_fade * image_color.a;
}
"""
	var material := ShaderMaterial.new()
	material.shader = shader
	material.render_priority = 97
	material.set_shader_parameter("distance_fade_enabled", distance_fade)
	material.set_shader_parameter("fade_start", fade_in_start)
	material.set_shader_parameter("fade_end", fade_in_end)
	material.set_shader_parameter("use_image", note_image != null)
	if note_image != null:
		material.set_shader_parameter("note_texture", note_image)
	return material

func configure_grid_material(node:MeshInstance3D) -> void:
	var source := node.get_active_material(0) as StandardMaterial3D
	var grid_texture:Texture2D
	var grid_color:Color
	var grid_priority:int
	if node.name == "Inner":
		grid_texture = load("res://assets/images/grid_inner.png")
		grid_color = Color(1.0, 1.0, 1.0, 0.352941)
		grid_priority = 98
	else:
		grid_texture = load("res://assets/images/grid_outer.png")
		grid_color = Color(1.0, 1.0, 1.0, 0.588235)
		grid_priority = 99
	if source != null:
		if source.albedo_texture != null:
			grid_texture = source.albedo_texture
		grid_color = source.albedo_color
		grid_priority = source.render_priority
	var shader := Shader.new()
	shader.code = """shader_type spatial;
render_mode blend_mix, cull_disabled, unshaded, depth_test_disabled;

uniform sampler2D grid_texture : source_color, filter_linear;
uniform vec4 grid_color : source_color = vec4(1.0);

void fragment() {
	vec4 tex = texture(grid_texture, UV);
	if (tex.a <= 0.001) {
		discard;
	}
	ALBEDO = tex.rgb * grid_color.rgb;
	ALPHA = tex.a * grid_color.a;
}
"""
	var material := ShaderMaterial.new()
	material.shader = shader
	material.render_priority = grid_priority
	material.set_shader_parameter("grid_texture", grid_texture)
	material.set_shader_parameter("grid_color", grid_color)
	node.material_override = material

func set_grid_color(node:MeshInstance3D, color:Color) -> void:
	var material := node.get_active_material(0)
	if material is ShaderMaterial:
		material.set_shader_parameter("grid_color", color)
	elif material is StandardMaterial3D:
		material.albedo_color = color

func note_reposition(i:int):
	var real_position:Vector2 = note_positions[i]
	var notems:float = notes[i]
	var state:int = note_states[i]
	var col:Color = note_color(i)
	var nt:Transform3D = note_transform(i)
	
	var approachSpeed:float = approach_rate / speed_multi
	
	var current_offset_ms:float = notems - ms
	var current_dist:float = approachSpeed*current_offset_ms/1000
	
	if (
		(current_dist <= Rhythia.get("spawn_distance") and current_dist >= (grid_pushback * -1) and sign(approachSpeed) == 1) or
		(current_dist >= -50 and current_dist <= 0.1 and sign(approachSpeed) == -1) or
		sign(approachSpeed) == 0
	) and state == Globals.NSTATE_ACTIVE: # state 2 = miss # and current_dist >= -0.5
		
#		if !was_visible:
#			was_visible = true
#			if Rhythia.note_spawn_effect:
#				if !Rhythia.mod_nearsighted: spawn_effect_t = 1
		
		
		nt.origin.z = -current_dist
#		visible = true
		
		var spawn_effect_t = 1 - clamp(4*(Rhythia.spawn_distance - current_dist)/Rhythia.spawn_distance, 0, 1)
		if Rhythia.note_spawn_effect:
			$SpawnEffect.multimesh.set_instance_color(i - current_note, Color(col.r, col.g, col.b, col.a))
			if spawn_effect_t != 0:
				var effect_transform = Transform3D.IDENTITY
				effect_transform.origin = nt.origin
				effect_transform.basis = effect_transform.basis.scaled(Vector3.ONE * 1 * Rhythia.note_size)
				effect_transform.basis = effect_transform.basis.scaled(Vector3(1*spawn_effect_t, 0.9 + (0.1*spawn_effect_t), 1))
				effect_transform.basis = effect_transform.basis.rotated(Vector3(1,0,0), deg_to_rad(90))
				$SpawnEffect.multimesh.set_instance_transform(i - current_note, effect_transform)
			else: $SpawnEffect.multimesh.set_instance_transform(i - current_note, Transform3D.IDENTITY.scaled(Vector3.ZERO))
		
		if Rhythia.mod_chaos:
			var chaos_offset:Vector2 = note_chaos_offsets[i]
			var v = ease(max((current_offset_ms-250)/400,0),1.5)
			nt.origin.x = real_position.x + (chaos_offset.x * v)	
			nt.origin.y = real_position.y + (chaos_offset.y * v)
		
		if Rhythia.mod_earthquake:
			var rcoord = Vector2(earthquake_rng.randf_range(-0.25,0.25),earthquake_rng.randf_range(-0.25,0.25))
			nt.origin.x = real_position.x + (rcoord.x * (current_dist * 0.1))
			nt.origin.y = real_position.y + (rcoord.y * (current_dist * 0.1))

#		if Rhythia.note_visual_approach:
#			$Approach.opacity = 1 - (current_dist / Rhythia.get("spawn_distance"))
#
#			$Approach.scale.x = 0.4 * ((current_dist / Rhythia.get("spawn_distance")) + 0.6)
#			$Approach.scale.y = 0.4 * ((current_dist / Rhythia.get("spawn_distance")) + 0.6)
#
#			$Approach.global_translation.z = 0
			
		# note spin; not doing this all in a single Vector3 because we're trying to rotate locally
		nt.basis = nt.basis.rotated(Vector3(1,0,0),Rhythia.note_spin_x / 2000)
		nt.basis = nt.basis.rotated(Vector3(0,1,0),Rhythia.note_spin_y / 2000)
		nt.basis = nt.basis.rotated(Vector3(0,0,1),Rhythia.note_spin_z / 2000)
		
		var alpha:float = Rhythia.note_opacity
		var fade_in:float = 1
		var fade_out:float = 1
		
		if fade_in_enabled or fade_out_enabled:
			
			if fade_in_enabled: 
				fade_in = (pow(linstep(fade_in_start,fade_in_end,current_dist), 1.3)) * Rhythia.note_opacity
			if fade_out_enabled:
				fade_out = ((1 - fade_out_base) + (pow(linstep(fade_out_end,fade_out_start,current_dist), 1.3) * fade_out_base)) * Rhythia.note_opacity
			
			alpha = min(fade_in,fade_out)
		
		
		var instance_color := Color(col.r, col.g, col.b, col.a * alpha)
		$Notes.multimesh.set_instance_transform(i - current_note, nt)
		$Notes.multimesh.set_instance_color(i - current_note, instance_color)
		$Notes.multimesh.set_instance_custom_data(i - current_note, instance_color)
		if asq:
			var sc = (linstep(0,Rhythia.get("spawn_distance"),current_dist) + 0.6) * 0.4
			
			var at = Transform3D()
			at = at.scaled(Vector3(sc,sc,sc))
			at.origin = nt.origin#Vector3(nt.origin.x, nt.origin.y, 0)
			if !Rhythia.visual_approach_follow:
				at.origin.z = 0
			
			$ASq.multimesh.set_instance_transform(i - current_note, at)
			if Rhythia.mod_ghost:
				$ASq.multimesh.set_instance_color(i - current_note, Color(1,1,1,1 * alpha))
			else:
				$ASq.multimesh.set_instance_color(i - current_note, Color(1,1,1,pow(linstep(Rhythia.get("spawn_distance"),0,current_dist),1.7)))
		
#		$Label.text += "(%.02f: %s -> %s = %s) %s\n" % [current_dist,fade_in_start,fade_in_end,fade_in,alpha]
		
		return true
	else:
		$Notes.multimesh.set_instance_transform(i - current_note, Transform3D(Basis(), Vector3(0, 0, 10)))
		$Notes.multimesh.set_instance_color(i - current_note, Color(0,0,0,0))
		$Notes.multimesh.set_instance_custom_data(i - current_note, Color(0,0,0,0))
		if asq:
			$ASq.multimesh.set_instance_transform(i - current_note, Transform3D(Basis(), Vector3(0, 0, 10)))
			$ASq.multimesh.set_instance_color(i - current_note, Color(0,0,0,0))
		if Rhythia.note_spawn_effect:
			$SpawnEffect.multimesh.set_instance_transform(i - current_note, Transform3D(Basis(), Vector3(0, 0, 10)))
			$SpawnEffect.multimesh.set_instance_color(i - current_note, Color(0,0,0,0))
#		if Rhythia.play_hit_snd and Rhythia.ensure_hitsync: 
#			if Rhythia.sfx_2d:
#				$"../Hit2D".play()
#			else:
#				$"../Hit".transform = transform
#				$"../Hit".play()
#		visible = false
		return false#!(state == Globals.NSTATE_ACTIVE and sign(approachSpeed) == 1 and current_dist > 100)

func note_check_collision(i:int):
	var cpos:Vector3 = $Cursor.transform.origin
	
	if Rhythia.replaying and Rhythia.replay.sv != 1:
		return Rhythia.replay.should_hit(i)
	else:
		var hbs:float = Rhythia.note_hitbox_size/2
		if hbs == 0.57: hbs = 0.56875 # 1.1375
		var ori:Vector2 = note_positions[i]
		return (cpos.x <= ori.x + hbs and cpos.x >= ori.x - hbs) and (cpos.y <= ori.y + hbs and cpos.y >= ori.y - hbs)

func resolve_note(i:int, notems:float) -> bool:
	var result = Rhythia.visual_mode or note_check_collision(i)
	var col := note_color(i)
	var event_transform := note_transform(i, 0.0)
	if !result and (ms > notems + hit_window or pause_state == -1):
		if !Rhythia.replaying and Rhythia.record_replays:
			Rhythia.replay.note_miss(i)
		note_states[i] = Globals.NSTATE_MISS
		if Rhythia.play_miss_snd:
			if Rhythia.sfx_2d:
				$Miss2D.play()
			else:
				$Miss.transform = event_transform
				$Miss.play()
		if Rhythia.show_miss_effect:
			var pos := Vector3(event_transform.origin.x, event_transform.origin.y, 0.002)
			missEffect.duplicate().spawn(self,pos,col,miss_id,true)
		emit_signal("miss",col)
		prev_ms = notems
		return true
	elif result:
		if !Rhythia.replaying and Rhythia.record_replays:
			Rhythia.replay.note_hit(i)
		note_states[i] = Globals.NSTATE_HIT
		if Rhythia.play_hit_snd:
			SFXManager.play_hitsfx(event_transform)
		var pos := Vector3($Cursor.global_transform.origin.x, $Cursor.global_transform.origin.y, 0.002)
		if Rhythia.show_hit_effect and !Rhythia.visual_mode:
			if !Rhythia.hit_effect_at_cursor:
				pos.x = (global_transform * event_transform).origin.x
				pos.y = (global_transform * event_transform).origin.y
			hitEffect.duplicate().spawn(get_parent(),pos,col,hit_id,false)
		emit_signal("hit",col)
		var score:int = get_parent().hit(col)
		if Rhythia.score_popup:
			scoreEffect.duplicate().spawn(get_parent(),pos,col,score)
		prev_ms = notems
		return true
	return false

var asq = Rhythia.note_visual_approach
var last_reposition_ms:float = -10000
var out_of_notes:bool = false
func reposition_notes(force:bool=false,rerun_start:int=-1):
	var rerun_required:bool = false
	$Label.text = ""
#	force = force or OS.has_feature("debug")
	if current_note == notes.size():
#		$Label.text += "out_of_notes\n"
		$Notes.multimesh.visible_instance_count = 0
		if asq: $ASq.multimesh.visible_instance_count = 0
		if Rhythia.note_spawn_effect: $SpawnEffect.multimesh.visible_instance_count = 0
		out_of_notes = true
		return false
	
	var note_passed:bool = false
	var is_first:bool = true
	
#	$Label.text += "ms: %s\n\n" % [ ms ]
#	$Label.text += "current: %s\n" % [ current_note ]
#	$Label.text += "total: %s\n" % [ notes.size() ]
#	$Label.text += "visible: %s\n" % [ $Notes.multimesh.visible_instance_count ]
	
	if last_reposition_ms > ms:
#		$Label.text += "rewind detected\n"
		print("rewind detected")
		for i in range(0, notes.size()):
			if notes[i] > ms:
				current_note = max(i - 1, 0)
				break
	
	last_reposition_ms = ms
	
	for i in range(max(current_note,rerun_start), notes.size()):
		if (i - current_note + 2) > $Notes.multimesh.instance_count:
			rerun_required = true
			$Notes.multimesh.instance_count = min($Notes.multimesh.instance_count + 10, notes.size())
			if asq: $ASq.multimesh.instance_count = $Notes.multimesh.instance_count
			if Rhythia.note_spawn_effect: $SpawnEffect.multimesh.instance_count = $Notes.multimesh.instance_count
			break
		
		var notems:float = notes[i]
		var col:Color = note_color(i)
		next_ms = notems
		if force:
#			if is_first: $Label.text += "force\n"
			if note_reposition(i) == false:
				$Notes.multimesh.visible_instance_count = i - current_note + 1
				if asq: $ASq.multimesh.visible_instance_count = i - current_note + 1
				if Rhythia.note_spawn_effect: $SpawnEffect.multimesh.visible_instance_count = i - current_note
				return note_passed
		else:
			if note_reposition(i) == false:
#				$Label.text += "(%s) reposition == false\n" % [ i ]
				$Notes.multimesh.visible_instance_count = i - current_note + 1
				if asq: $ASq.multimesh.visible_instance_count = i - current_note + 1
				if Rhythia.note_spawn_effect: $SpawnEffect.multimesh.visible_instance_count = i - current_note
				if ms < notems:
#					$Label.text += "(%s) note is end of visible area\n" % [ i ]
					if note_states[i] == Globals.NSTATE_ACTIVE:
						return note_passed
		
		if ms < notems and is_first:
			is_first = false
#			$Label.text += "next_ms: %s\n" % [ notems ]
#			next_ms = notems
		elif ms >= notems and note_states[i] == Globals.NSTATE_ACTIVE:
			if resolve_note(i, notems):
				note_passed = true
		elif ms > (notems + hit_window) + 100:
#			$Label.text += "PASS %s\n" % [ i ]
		
			current_note = i + 1
#	$Label.text += "last note is visible!"
	$Notes.multimesh.visible_instance_count = notes.size() - current_note
	if asq: $ASq.multimesh.visible_instance_count = notes.size() - current_note
	if Rhythia.note_spawn_effect: $SpawnEffect.multimesh.visible_instance_count = notes.size() - current_note
	
	if rerun_required: reposition_notes()
	return note_passed

func dense_hide_note(i:int) -> void:
	var slot:int = i % $Notes.multimesh.instance_count
	$Notes.multimesh.set_instance_transform(slot, Transform3D(Basis(), Vector3(0, 0, 10000)))
	$Notes.multimesh.set_instance_color(slot, Color(0,0,0,0))
	$Notes.multimesh.set_instance_custom_data(slot, Color(0,0,0,0))

func dense_load_note(i:int) -> void:
	var slot:int = i % $Notes.multimesh.instance_count
	var nt := note_transform(i, -dense_approach_speed * (notes[i] - dense_time_origin_ms) / 1000.0)
	$Notes.multimesh.set_instance_transform(slot, nt)
	var col := note_color(i)
	var instance_color := Color(col.r, col.g, col.b, col.a * Rhythia.note_opacity)
	$Notes.multimesh.set_instance_color(slot, instance_color)
	$Notes.multimesh.set_instance_custom_data(slot, instance_color)

func dense_reposition_active_notes() -> void:
	for i in range(current_note, dense_loaded_until):
		if note_states[i] != Globals.NSTATE_ACTIVE:
			continue
		var slot:int = i % $Notes.multimesh.instance_count
		var z:float = -dense_approach_speed * (notes[i] - dense_time_origin_ms) / 1000.0
		$Notes.multimesh.set_instance_transform(slot, note_transform(i, z))

func dense_update_notes() -> bool:
	var note_passed := false
	var hit_count := 0
	var miss_count := 0
	var last_hit_color := Color.WHITE
	var last_miss_color := Color.WHITE
	if abs(ms - dense_time_origin_ms) >= DENSE_REBASE_INTERVAL_MS:
		dense_time_origin_ms = ms
		dense_reposition_active_notes()
	$Notes.position.z = dense_approach_speed * (ms - dense_time_origin_ms) / 1000.0
	var capacity:int = $Notes.multimesh.instance_count
	while dense_loaded_until < notes.size():
		if notes[dense_loaded_until] > ms + dense_future_ms:
			break
		if dense_loaded_until - current_note >= capacity:
			break
		dense_load_note(dense_loaded_until)
		dense_loaded_until += 1
	$Notes.multimesh.visible_instance_count = min(dense_loaded_until, capacity)

	var i := current_note
	while i < dense_loaded_until and notes[i] <= ms:
		if note_states[i] == Globals.NSTATE_ACTIVE:
			var result := Rhythia.visual_mode or note_check_collision(i)
			if result:
				note_states[i] = Globals.NSTATE_HIT
				hit_count += 1
				last_hit_color = note_color(i)
				dense_hide_note(i)
				prev_ms = notes[i]
				note_passed = true
			else:
				note_states[i] = Globals.NSTATE_MISS
				miss_count += 1
				last_miss_color = note_color(i)
				dense_hide_note(i)
				prev_ms = notes[i]
				note_passed = true
		i += 1
	if hit_count > 0:
		get_parent().dense_hits(hit_count, last_hit_color)
	if miss_count > 0:
		get_parent().dense_misses(miss_count, last_miss_color)
	while current_note < notes.size() and note_states[current_note] != Globals.NSTATE_ACTIVE:
		current_note += 1
	if current_note < notes.size():
		next_ms = notes[current_note]
	else:
		out_of_notes = true
		$Notes.multimesh.visible_instance_count = 0
	return note_passed

var color_index:int = 0
var note_count:int = 0

func sort_note_nodes(a,b):
	return a.notems < b.notems

func sort_note_queue(a,b):
	return a[2] < b[2]

func spawn_notes(note_array:Array):
	var pack_started_at := Time.get_ticks_msec()
	if note_array.is_empty():
		notes_loaded = true
		return
	var is_sorted := true
	for i in range(1, note_array.size()):
		if note_array[i - 1][2] > note_array[i][2]:
			is_sorted = false
			break
	if not is_sorted:
		note_array.sort_custom(Callable(self, "sort_note_queue"))
	
	note_index_offset = 0
	while note_index_offset < note_array.size() and note_array[note_index_offset][2] < Rhythia.start_offset:
		note_index_offset += 1
	var packed_note_count := note_array.size() - note_index_offset
	dense_rendering = packed_note_count >= 100000 and approach_rate > 0
	if dense_rendering:
		dense_approach_speed = approach_rate / speed_multi
		dense_future_ms = max(0.0, (Rhythia.get("spawn_distance") / dense_approach_speed) * 1000.0)
		dense_time_origin_ms = ms
		dense_peak_window_count = 0
	var dense_center := Vector2(1,-1)
	var dense_position_scale := 1.0
	var dense_grid_step := INF
	if dense_rendering and packed_note_count > 0:
		var min_position := Vector2(INF, INF)
		var max_position := Vector2(-INF, -INF)
		var previous_position := Vector2(float(note_array[note_index_offset][0]), -float(note_array[note_index_offset][1]))
		for source_i in range(note_index_offset, note_array.size()):
			var source_position := Vector2(float(note_array[source_i][0]), -float(note_array[source_i][1]))
			min_position.x = min(min_position.x, source_position.x)
			min_position.y = min(min_position.y, source_position.y)
			max_position.x = max(max_position.x, source_position.x)
			max_position.y = max(max_position.y, source_position.y)
			var dx:float = abs(source_position.x - previous_position.x)
			var dy:float = abs(source_position.y - previous_position.y)
			if dx >= 0.001: dense_grid_step = min(dense_grid_step, dx)
			if dy >= 0.001: dense_grid_step = min(dense_grid_step, dy)
			previous_position = source_position
		dense_center = (min_position + max_position) * 0.5
		var bounds_size:Vector2 = max_position - min_position
		dense_position_scale = min(1.0, min(2.8 / max(bounds_size.x, 0.001), 2.8 / max(bounds_size.y, 0.001)))
	var nscale:float = 0.45 * Rhythia.note_size * (Rhythia.note_hitbox_size / 1.14)
	if dense_rendering and dense_grid_step != INF:
		nscale = min(nscale, dense_grid_step * dense_position_scale * 0.6)
	note_transform_scale = Vector3(nscale, nscale, nscale)
	notes.resize(packed_note_count)
	note_positions.resize(packed_note_count)
	note_states.resize(packed_note_count)
	if Rhythia.mod_chaos:
		note_chaos_offsets.resize(packed_note_count)
	var dense_window_start:int = 0
	for i in range(packed_note_count):
		var data:Array = note_array[i + note_index_offset]
		var position := Vector2(float(data[0]), -float(data[1]))
		if dense_rendering:
			position = (position - dense_center) * dense_position_scale + Vector2(1,-1)
		if Rhythia.mod_hardrock: position = ((position - Vector2(1,-1)) * 1.35) + Vector2(1,-1)
		if Rhythia.mod_mirror_x: position.x = 2 - position.x
		if Rhythia.mod_mirror_y: position.y = (-position.y) - 2
		note_positions[i] = position
		notes[i] = float(data[2])
		note_states[i] = Globals.NSTATE_ACTIVE
		if dense_rendering:
			while dense_window_start < i and notes[i] - notes[dense_window_start] > dense_future_ms:
				dense_window_start += 1
			dense_peak_window_count = max(dense_peak_window_count, i - dense_window_start + 1)
		if Rhythia.mod_chaos:
			note_chaos_offsets[i] = Vector2(
				chaos_rng.randf_range(-1,1),
				chaos_rng.randf_range(-1,1)
			).normalized() * 2
	note_array.clear()
	print("NOTE_PACKED elapsed_ms=%d notes=%d" % [Time.get_ticks_msec() - pack_started_at, notes.size()])
	if notes.is_empty():
		notes_loaded = true
		return
	next_ms = notes[0]
	var last_ms = notes[-1]
	var inst_count:int
	if dense_rendering:
		var dense_capacity_margin:int = max(256, int(ceil(dense_peak_window_count * 0.1)))
		inst_count = max(4096, dense_peak_window_count + dense_capacity_margin)
		var dense_visible_depth:float = max(
			32.0,
			dense_approach_speed * (dense_future_ms + DENSE_REBASE_INTERVAL_MS) / 1000.0 + 4.0
		)
		$Notes.multimesh.custom_aabb = AABB(
			Vector3(-4.0, -4.0, -dense_visible_depth),
			Vector3(8.0, 8.0, dense_visible_depth + 8.0)
		)
		print("NOTE_DENSE_LAYOUT position_scale=%.4f grid_step=%.4f note_scale=%.4f approach_ms=%.1f peak=%d" % [
			dense_position_scale, dense_grid_step, nscale, dense_future_ms, dense_peak_window_count
		])
	else:
		var instance_window_ms := 10000.0
		inst_count = max(35, int(ceil(instance_window_ms * (float(notes.size()) / float(last_ms)))))
	$Notes.material_override = create_note_instance_material(dense_rendering and fade_in_enabled)
	$Notes.multimesh.instance_count = inst_count
	$Notes.multimesh.visible_instance_count = 0
	if asq:
		$ASq.multimesh.instance_count = inst_count
		$ASq.multimesh.visible_instance_count = 0
	if Rhythia.note_spawn_effect:
		$SpawnEffect.multimesh.instance_count = inst_count
		$SpawnEffect.multimesh.visible_instance_count = 0
		if dense_rendering:
			$SpawnEffect.visible = false
	if dense_rendering and asq:
		$ASq.visible = false
	print("NOTE_MULTIMESH_READY elapsed_ms=%d instances=%d" % [Time.get_ticks_msec() - pack_started_at, inst_count])
		
	notes_loaded = true
	if dense_rendering:
		call_deferred("dense_update_notes")
	else:
		call_deferred("reposition_notes",true)


func _ready():
	if Rhythia.do_note_pushback:
		grid_pushback = pushback_defaults.do_pushback
	else:
		grid_pushback = pushback_defaults.never

	if Rhythia.speed_hitwindow:
		hit_window = Rhythia.get("hitwindow_ms") * speed_multi
	
	if Rhythia.mod_hardrock:
		hit_window = hit_window * 0.8

	$Note.speed_multi = speed_multi
	$Music.pitch_scale = speed_multi
	# reset any pitch shift
	if AudioServer.get_bus_effect_count(AudioServer.get_bus_index("Music")) > 0:
		AudioServer.remove_bus_effect(AudioServer.get_bus_index("Music"),0)
	if Rhythia.retain_song_pitch and not speed_multi == 1.0 :
		var shift = AudioEffectPitchShift.new()
		shift.pitch_scale = 1.0 / speed_multi
		AudioServer.add_bus_effect(AudioServer.get_bus_index("Music"),shift)
	$Miss.stream = Rhythia.miss_snd
#	$Hit.stream = Rhythia.hit_snd
	$Miss2D.stream = Rhythia.miss_snd
#	$Hit2D.stream = Rhythia.hit_snd
	SFXManager.setup()
	
	
	if !Rhythia.replaying and Rhythia.record_replays:
		Rhythia.replay = Replay.new()
		Rhythia.replay.start_recording(Rhythia.selected_song)
	
	chaos_rng.seed = hash(Rhythia.selected_song.id)
	earthquake_rng.seed = hash(Rhythia.selected_song.id)
	
	
	if Rhythia.mod_ghost:
		fade_out_enabled = true
		fade_out_start = ((18.0/50)*approach_rate)
		fade_out_end = ((6.0/50.0)*approach_rate)
		
	elif Rhythia.half_ghost:
		fade_out_enabled = true
		fade_out_start = ((12.0/50)*approach_rate)
		fade_out_end = ((3.0/50.0)*approach_rate)
		fade_out_base = 0.8
	
	if Rhythia.mod_nearsighted:
		fade_in_enabled = true
		fade_in_start = ((30.0/50.0)*approach_rate)
		fade_in_end = ((5.0/50.0)*approach_rate)
	else:
		fade_in_enabled = Rhythia.get("fade_length") != 0
		if Rhythia.get("fade_length") != 0: 
			fade_in_start = Rhythia.get("spawn_distance")
			fade_in_end = Rhythia.get("spawn_distance")*(1.0 - Rhythia.get("fade_length"))
	
	
	$Notes.multimesh = MultiMesh.new()
	$Notes.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	$Notes.multimesh.use_colors = true
	$Notes.multimesh.use_custom_data = true
	$Notes.multimesh.instance_count = 1
	if asq:
		$ASq.multimesh = MultiMesh.new()
		$ASq.multimesh.transform_format = MultiMesh.TRANSFORM_3D
		$ASq.multimesh.use_colors = true
		$ASq.multimesh.mesh = QuadMesh.new()
		$ASq.multimesh.mesh.size = Vector2(3.35,3.35)
		$ASq.multimesh.mesh.surface_set_material(0,asq_mat)
		$ASq.multimesh.instance_count = 1
	else:
		$ASq.visible = false
	
	
	var mesh:Mesh
	if "user://" in Rhythia.selected_mesh.path:
		var m = ObjParse.load_obj(Rhythia.selected_mesh.path)
		if m != null:
			mesh = m
		else:
			mesh = load("res://assets/blocks/rounded.obj")
	else:
		mesh = load(Rhythia.selected_mesh.path)
	
	
	note_image = Globals.imageLoader.load_if_exists("user://note")
	if note_image:
		note_solid_mat.set_shader_parameter("image",note_image)
		note_transparent_mat.set_shader_parameter("image",note_image)
		note_solid_mat.set_shader_parameter("use_image",true)
		note_transparent_mat.set_shader_parameter("use_image",true)
	
	mesh.surface_set_material(0,note_solid_mat)
	if mesh.get_surface_count() > 1:
		mesh.surface_set_material(1,note_transparent_mat)
	if mesh.get_surface_count() > 2:
		mesh.surface_set_material(2,note_solid_mat)
		
	$Notes.multimesh.mesh = mesh
	configure_grid_material($Inner)
	configure_grid_material($Outer)
	
	# setup for effects (user://hit and user://miss images)
	if hitEffect.has_method("setup"): hitEffect.setup(hit_id,false)
	hitEffect.visible = false
	add_child(hitEffect)
	
	if missEffect.has_method("setup"): missEffect.setup(miss_id,true)
	missEffect.visible = false
	add_child(missEffect)
	
	# force everything to be loaded now
	await get_tree().process_frame
	hitEffect.duplicate().spawn(get_parent(),Vector3(0,0,-400),Color(1,1,1),hit_id,false)
	missEffect.duplicate().spawn(self,Vector3(0,0,-400),Color(1,1,1),miss_id,true)
	$Notes.multimesh.set_instance_color(0,Color(0,0,0,0))
	$Notes.multimesh.set_instance_custom_data(0,Color(0,0,0,0))
	$Notes.multimesh.set_instance_transform(0,Transform3D())
	if asq:
		$ASq.multimesh.set_instance_color(0,Color(0,0,0,0))
		$ASq.multimesh.set_instance_transform(0,Transform3D())
	if Rhythia.note_spawn_effect:
		$SpawnEffect.multimesh.set_instance_transform(0, Transform3D(Basis(), Vector3(0, 0, 10)))
		$SpawnEffect.multimesh.set_instance_color(0, Color(0,0,0,0))
	$Note.visible = true
	$Note.transform.origin = Vector3(0,0,-400)
	await get_tree().process_frame
	$Note.visible = false
	
	# Precache notes
#	if Rhythia.visual_mode: # Precache a bunch of notes, because we're probably going to need them
#		for i in range(800):
#			var n = $Note.duplicate()
#			noteCache.append(n)
##			add_child(n)
#	else:
#		for i in range(25):
#			var n = $Note.duplicate()
#			noteCache.append(n)

var music_started:bool = false
const cursor_offset = Vector3(1,-1,0)
@onready var cam:Camera3D = get_node("../..").get_node("Camera3D")
var hlpower = (0.1 * Rhythia.get("parallax"))
@onready var Grid = get_node("../HUD")

func do_half_lock():
	var cursorpos = $Cursor.transform.origin
	if Rhythia.follow_drift_cursor:
		cursorpos += $Cursor/Mesh2.transform.origin
	var centeroff = cursorpos - cursor_offset
	var hlm = 0.25
	var uim = Rhythia.get("ui_parallax") * 0.1
	var grm = Rhythia.get("grid_parallax") * 0.1
	cam.transform.origin = Vector3(
		centeroff.x*hlpower*hlm, centeroff.y*hlpower*hlm, 3.75
	)
	Grid.transform.origin = Vector3(
		-centeroff.x*hlm*uim, -centeroff.y*hlm*uim, Grid.transform.origin.z
	)
	transform.origin = Vector3(
		-(centeroff.x*hlm*grm)-1, -(centeroff.y*hlm*grm)+1, 0
	)

var sh:Vector2 = Vector2(-0.5,-0.5)
var edgec:float = 0
func do_spin():
	var centeroff = get_node("../..").get_node("SpinPos").global_transform.origin + cursor_offset
	
	var cx = centeroff.x
	var cy = -centeroff.y
	cx = clamp(cx, (0 + sh.x + edgec), (3 + sh.x - edgec))
	cy = clamp(cy, (0 + sh.y + edgec), (3 + sh.y - edgec))
	centeroff.x = cx - cursor_offset.x
	centeroff.y = -cy - cursor_offset.y
	
	var hlm = 0.25
	var uim = Rhythia.get("ui_parallax") * 0.1
	var grm = Rhythia.get("grid_parallax") * 0.1
	Grid.transform.origin = Vector3(
		-centeroff.x*hlm*uim, -centeroff.y*hlm*uim, Grid.transform.origin.z
	)
	transform.origin = Vector3(
		-(centeroff.x*hlm*grm)-1, -(centeroff.y*hlm*grm)+1, 0
	)

func do_vr_cursor():
	var centeroff = Rhythia.vr_player.primary_ray.get_collision_point() + cursor_offset
	
	var cx = centeroff.x
	var cy = -centeroff.y
	cx = clamp(cx, (0 + sh.x + edgec), (3 + sh.x - edgec))
	cy = clamp(cy, (0 + sh.y + edgec), (3 + sh.y - edgec))
	centeroff.x = cx - cursor_offset.x
	centeroff.y = -cy - cursor_offset.y
	
	var hlm = 0.25
	var uim = Rhythia.get("ui_parallax") * 0.1
	var grm = Rhythia.get("grid_parallax") * 0.1
	cam.transform.origin = Vector3(
		centeroff.x*hlpower, centeroff.y*hlpower, 3.735
	)
	Grid.transform.origin = Vector3(
		-centeroff.x*hlm*uim, -centeroff.y*hlm*uim, Grid.transform.origin.z
	)
	transform.origin = Vector3(
		-(centeroff.x*hlm*grm)-1, -(centeroff.y*hlm*grm)+1, 0
	)
	get_node("Cursor").transform.origin = centeroff + cursor_offset

func comma_sep(number):
	var string = str(number)
	var mod = string.length() % 3
	var res = ""
	
	for i in range(0, string.length()):
		if i != 0 && i % 3 == mod:
			res += ","
		res += string[i]
	
	return res

var spawn_ms_dist:float = ((max(Rhythia.get("spawn_distance") / Rhythia.get("approach_rate"),0.6) * 1000) + 500)

func do_note_queue():
	pass
	#	var rem:int = 0
	#	for n in noteQueue:
	#		if n[2] <= (ms + (spawn_ms_dist * speed_multi)):
	#			rem += 1
	#
	#			spawn_note(n)
	#			noteQueue.remove(noteQueue.find(n))
	#		else:
	#			break


var rec_t:float = 0
var rms:float = 0
var rec_interval:float = 12
var pause_state:float = 0
var pause_cooldown:float = 0
var pause_ms:float = 0
var replay_unpause:bool = false
var can_skip:bool = ((next_ms-prev_ms) > 5000) and (next_ms >= max(ms+(3000*speed_multi),1100*speed_multi))
var ms_offset:float = 0

var replay_sig:Array = []
var last_usec = Time.get_ticks_usec()

func _set_rec_interval(delta:float):
	var newpos = $Cursor.transform.origin
	var diff = last_cursor_position.distance_to(newpos)/delta
	
	var min_interval = 30
	var max_interval = 144
	match Rhythia.record_limit:
		1:
			min_interval = 60
			max_interval = 240
	if Engine.max_fps != 0:
		max_interval = min(max_interval,Engine.max_fps)
		min_interval = min(min_interval,max_interval)
	var target_interval = min_interval+((diff/12)*(max_interval-min_interval))
	var new_interval = rec_interval
	if rec_interval != target_interval:
		match Rhythia.record_mode:
			0:
				new_interval = target_interval
			1:
				if target_interval > rec_interval: new_interval += (target_interval-rec_interval) * (delta / 0.2)
				else: new_interval += (target_interval-rec_interval) * (delta / 2)
			2:
				if target_interval > rec_interval: new_interval += (target_interval-rec_interval) * (delta / 2)
				else: new_interval = target_interval
	rec_interval = clamp(new_interval,min_interval,max_interval)
	
	last_cursor_position = newpos

func _process(delta:float):
	if Rhythia.vr: do_vr_cursor()
	elif Rhythia.get("cam_unlock"): do_spin()
	else: do_half_lock()
	
	_set_rec_interval(delta)
	
	if active and notes_loaded:
		if !notes_loaded: return
		can_skip = ((next_ms-prev_ms) > 5000) and (next_ms >= max(ms+(3000*speed_multi),1100*speed_multi)) and ($Notes.multimesh.visible_instance_count <= 1)
		
		$Cursor.can_switch_move_modes = (ms < Rhythia.music_offset)
		
		if !Rhythia.replaying:
			if Input.is_action_just_released("pause"):
				if pause_state > 0:
					pause_state = -1
					ms = pause_ms# - (750 * speed_multi)
					if Rhythia.record_replays:
						Rhythia.replay.store_sig(rms,Globals.RS_CANCEL_UNPAUSE)
					emit_signal("ms_change",ms)
					$Music.stop()
			elif Input.is_action_just_pressed("pause"):
				if pause_state == 0 and can_skip:
					var prev_ms = ms
					if Rhythia.record_replays:
						Rhythia.replay.store_sig(rms,Globals.RS_SKIP)
					ms = next_ms - 1000 - (1000*speed_multi)
					emit_signal("ms_change",ms)
					do_note_queue()
#					if (ms + Rhythia.music_offset) >= Rhythia.start_offset:
#						$Music.play((ms + Rhythia.music_offset)/1000)
#						music_started = true
				else:
					if pause_state == 0 and (ms > (1000 * speed_multi) and ms < get_parent().last_ms) and pause_cooldown == 0 and !Rhythia.disable_pausing:
						print("PAUSED AT MS %.0f" % ms)
						if Rhythia.record_replays:
							Rhythia.replay.store_pause(rms)
						Rhythia.song_end_pause_count += 1
						pause_state = -1
			#			ms -= 750
						emit_signal("ms_change",ms)
						pause_ms = ms# + (750 * speed_multi)
						$Music.stop()
						get_parent().combo_level = 1
						get_parent().lvl_progress = 0
						get_parent().update_hud()
					elif pause_state != 0:
						if Rhythia.record_replays:
							Rhythia.replay.store_sig(rms,Globals.RS_START_UNPAUSE)
						pause_state = 1
						ms = pause_ms - (pause_state * (750 * speed_multi))
						emit_signal("ms_change",ms)
						$Music.volume_db = -30
						$Music.play(ms/1000)
			if Input.is_action_pressed("pause") and pause_state > 0:
				var prev_state = pause_state
				pause_state = max(pause_state - (delta/0.75), 0)
				$Music.volume_db = min($Music.volume_db + (delta * 30), 0)
				if pause_state == 0:
		#				print("YEAH baby that's what i've been waiting for")
					if (prev_state != pause_state) and Rhythia.record_replays:
						Rhythia.replay.store_sig(rms,Globals.RS_FINISH_UNPAUSE)
					$Music.volume_db = 0
					pause_state = 0
					pause_cooldown = 1
			elif pause_state == 0:
				pause_cooldown = max(pause_cooldown - delta, 0)
		elif Rhythia.replay.sv != 1:
			var should_pause:bool = false
			var should_giveup:bool = false
			var should_skip:bool = false
			var just_started_unpause:bool = false
			var just_cancelled_unpause:bool = false
			var should_end_unpause:bool = false
			if replay_sig.size() != 0:
				print(replay_sig)
			for s in replay_sig:
				if s[1] == Globals.RS_PAUSE: should_pause = true
				elif s[1] == Globals.RS_GIVEUP: should_giveup = true
				elif s[1] == Globals.RS_SKIP: should_skip = true
				elif s[1] == Globals.RS_START_UNPAUSE:
					just_started_unpause = true
					replay_unpause = true
				elif s[1] == Globals.RS_CANCEL_UNPAUSE:
					just_cancelled_unpause = true
					replay_unpause = false
				elif s[1] == Globals.RS_FINISH_UNPAUSE:
					should_end_unpause = true

			if should_skip:
				var prev_ms = ms
				if Rhythia.record_replays:
					Rhythia.replay.store_sig(rms,Globals.RS_SKIP)
				ms = next_ms - 1000 - (1000*speed_multi)
				emit_signal("ms_change",ms)
				do_note_queue()
				if (ms + Rhythia.music_offset) >= Rhythia.start_offset:
					$Music.play((ms + Rhythia.music_offset)/1000)
					music_started = true
			if just_cancelled_unpause:
				pause_state = -1
				ms = pause_ms# - (750 * speed_multi)
				Rhythia.replay.store_sig(rms,Globals.RS_CANCEL_UNPAUSE)
				emit_signal("ms_change",ms)
				$Music.stop()
			elif should_pause:
				print("PAUSED AT MS %.0f" % ms)
				if Rhythia.record_replays:
					Rhythia.replay.store_sig(rms,Globals.RS_PAUSE)
				Rhythia.song_end_pause_count += 1
				pause_state = -1
	#			ms -= 750
				emit_signal("ms_change",ms)
				pause_ms = ms# + (750 * speed_multi)
				$Music.stop()
				get_parent().combo_level = 1
				get_parent().lvl_progress = 0
				get_parent().update_hud()
			elif just_started_unpause:
	#				print("YEAH baby that's what i've been waiting for")
	#				print(pause_ms)
				pause_state = 1
				ms = pause_ms - (pause_state * (750 * speed_multi))
				emit_signal("ms_change",ms)
				$Music.volume_db = -30
				$Music.play((ms + Rhythia.music_offset)/1000)
			if replay_unpause and pause_state >= 0:
				pause_state = max(pause_state - (delta/0.75), 0)
				$Music.volume_db = min($Music.volume_db + (delta * 30), 0)
				if should_end_unpause:
		#				print("YEAH baby that's what i've been waiting for")
					$Music.volume_db = Rhythia.music_volume_db
					pause_state = 0
			if should_giveup: get_parent().end(Globals.END_GIVEUP)
		
		rms += delta * 1000
		rec_t += delta
		if pause_state == 0 or (pause_state > 0 and (Input.is_action_pressed("pause") or replay_unpause)):
			ms += delta * 1000 * speed_multi
			emit_signal("ms_change",ms)
			do_note_queue()
			if (ms + Rhythia.music_offset) >= Rhythia.start_offset and !music_started:
				$Music.play((ms + Rhythia.music_offset)/1000)
				music_started = true
		
		if Rhythia.replaying:
			replay_sig = Rhythia.replay.get_signals(rms)
		
		emit_signal("timer_update",ms,can_skip)
		
		if $Music.playing and !Rhythia.disable_desync:
			var playback_pos:float = $Music.get_playback_position()*1000.0
			if abs(playback_pos - (ms + Rhythia.music_offset)) > (100 * max(speed_multi, 1.0)):
				if Rhythia.desync_alerts:
					Globals.notify(
						Globals.NOTIFY_WARN,
						"Audio was desynced by %.2f ms, correcting." % [playback_pos - (ms + Rhythia.music_offset)],
						"Music Sync Correction"
					)
				$Music.play((ms + Rhythia.music_offset)/1000.0)
		
		var rn_res:bool = dense_update_notes() if dense_rendering else reposition_notes()
		if !Rhythia.replaying and Rhythia.record_replays:
			var should_write_pos:bool = rn_res
			var ri = 1/round(max(32,rec_interval))
			if pause_state == -1: ri /= 3
			if rn_res or rec_t >= ri:
				rec_t = 0
				should_write_pos = true
				Rhythia.replay.store_cursor_pos(rms,$Cursor.rpos.x,$Cursor.rpos.y)
		
		if Rhythia.rainbow_grid:
			var color := Color.from_hsv(Rhythia.rainbow_t*0.1,0.65,1)
			set_grid_color($Inner, color)
			set_grid_color($Outer, color)


func _exit_tree():
	# Remove anything sitting outside of the tree
	scoreEffect.queue_free()
	for n in noteCache:
		n.queue_free()
