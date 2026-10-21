extends ColorPickerButton

@export var target: String

func upd():
	await get_tree().process_frame
	print(target, " ", color.to_html(color.a != 1))
	Rhythia.set(target,color)

#func _process(_d):
#	if color != Rhythia.get(target): upd()
	
func _ready():
	color = Rhythia.get(target)
	connect("popup_closed", Callable(self, "upd"))
