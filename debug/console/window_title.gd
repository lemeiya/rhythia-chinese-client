extends Label

var lifted = false
var mouseinside = false

func _input(event):
	if lifted and event is InputEventMouseMotion:
		get_parent().position += event.relative
	if event is InputEventMouseButton && event.get_button_index() == 1:
		if event.pressed:
			if event.position.x >= global_position.x and event.position.x <= global_position.x + size.x and event.position.y >= global_position.y and event.position.y <= global_position.y + size.y:
				lifted = true
		else:
			lifted = false
