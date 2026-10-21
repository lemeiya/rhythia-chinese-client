extends MeshInstance3D

var time:float = 0

func _process(delta):
	time += delta
	self.mesh.material.set_shader_parameter('time_float', time)
