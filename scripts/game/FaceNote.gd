extends MeshInstance3D

@export var look_multi = 1.0
@export var speed_multi = 1.0

var ok = false
var enabled = false

func _ready():
	ok = true

func _process(delta):
	if get_parent().get_parent().has_node("Spawn/Cursor") and enabled:
		var clpos:Vector3
		clpos += (get_parent().get_parent().get_node("Spawn/Cursor").position - clpos) * speed_multi
		look_at(clpos * look_multi,Vector3(0,1,0))
	else:
		pass
