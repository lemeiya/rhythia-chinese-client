extends RayCast3D

func update_beam():
	var dist = -target_position.z
	if is_colliding():
		dist = (get_collision_point() - global_transform.origin).length()
	
	$Beam.mesh.height = dist
	$Beam.transform.origin.z = -dist/2.0

func _process(_delta):
	$Beam.visible = enabled
