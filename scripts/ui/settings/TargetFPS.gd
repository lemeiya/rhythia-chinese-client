extends SpinBox

func upd():
	if value < 15 and value != 0:
		value = 15
	Engine.max_fps = value

func _process(_d):
	if value != Engine.max_fps: upd()
	
func _ready():
	value = Engine.max_fps
	connect("changed", Callable(self, "upd"))
