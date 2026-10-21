extends Control

var rng = RandomNumberGenerator.new()
var fading = false
var target:String
var _timer:float = 0
@export var trigger:float = false

func _process(delta):
	randomize()
	$Label.position = Vector2(rng.randf_range(-5,5),rng.randf_range(-10,10))
	$Label.rotation = rng.randf_range(-0.5,0.5)
	$Label.text = target
	if trigger:
		visible = true
		$Label.modulate.a = lerp($Label.modulate.a,1,0.001)
