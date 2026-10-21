extends Node3D

func _process(delta):
	if get_parent().get_parent().has_node("Spawn/Cursor"):
		look_at(get_parent().get_parent().get_node("Spawn/Cursor").position - Vector3(2,0,0),Vector3.UP)
	else:
		pass
