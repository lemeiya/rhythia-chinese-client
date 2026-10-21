extends Label

func _ready():
	if !Rhythia.display_true_combo:
		visible = false
	else:
		visible = true
		
func _physics_process(delta):
	position.y += (150 - position.y) * 0.25
