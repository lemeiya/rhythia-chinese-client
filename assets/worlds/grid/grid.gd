extends Node3D

var rate:float = 6
var s:float = -26
var e:float = -14.1
var gcol:Color
var color:Color = Rhythia.selected_colorset.colors[0]
var ratec:float = 0.005
var rng = RandomNumberGenerator.new()
var particle = preload("res://assets/worlds/grid/cube.tscn")

func hit(col:Color):
	color = col
	if !Rhythia.disable_bg_effects:
		var particle_instance = particle.instantiate()
		particle_instance.translate(Vector3(randf_range(-$emissionArea.scale.x, $emissionArea.scale.x), 4, randf_range(-$emissionArea.scale.z, $emissionArea.scale.z)))
		if (particle_instance.position.x >= -5 and particle_instance.position.x <= 5):
			return
		particle_instance.process_material.color = color
		particle_instance.process_material.scale = randf_range(0.5, 1)
		particle_instance.speed_scale = randf_range(1, 2)
		particle_instance.lifetime = 2
		particle_instance.restart()
		particle_instance.emitting = true
		$Particles.call_deferred("add_child", particle_instance)
		get_tree().create_timer(particle_instance.lifetime).connect("timeout", Callable(particle_instance, "queue_free"))

func _ready():
	get_parent().get_node("Game").connect("note_hit", Callable(self, "hit"))
	# Shaders
	var env = get_node("WorldEnvironment").environment
	if Rhythia.glow > 0:
		env.glow_enabled = true
		env.glow_intensity = Rhythia.glow
		env.glow_strength = 1
		env.glow_bloom = Rhythia.bloom
		env.glow_blend_mode = 1
		env.glow_hdr_scale = 1.72
		env.glow_high_quality = true
		env.glow_bicubic_upscale = true
		
		
func _process(delta):
	$gridBottom.position.z += rate * delta 
	$gridTop.position.z += rate * delta 
	
	$gridBottom.position.z = wrapf($gridBottom.position.z,s,e)
	$gridTop.position.z = wrapf($gridTop.position.z,s,e)

	gcol = Color(color.r,color.g,color.b,0.01)

	$gridBottom.material_override.albedo_color = lerp($gridBottom.material_override.albedo_color,gcol,ratec)
	$gridTop.material_override.albedo_color = lerp($gridTop.material_override.albedo_color,gcol,ratec)
	$gridBottomF.material_override.albedo_color = lerp($gridBottomF.material_override.albedo_color,gcol,ratec)
	$gridTopF.material_override.albedo_color = lerp($gridTopF.material_override.albedo_color,gcol,ratec)
