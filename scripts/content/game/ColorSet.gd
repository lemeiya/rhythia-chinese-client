extends Resource
class_name ColorSet

@export var id: String
@export var name: String
@export var creator: String
@export var colors:Array:
	get:
		return _get_colors()
	set(value):
		_set_colors(value)
var real_colors:Array
@export var mirror: bool

func _get_colors():
	if mirror:
		var mirrored_colors := real_colors.duplicate()
		for i in range(real_colors.size()-2,0,-1):
			mirrored_colors.append(real_colors[i])
		return mirrored_colors
	else:
		return real_colors

func _set_colors(v:Array):
	real_colors = v

func _init(colorsI:Array, idI:String, nameI:String, creatorI:String="Unknown"):
	id = idI
	name = nameI
	real_colors = colorsI
	creator = creatorI
