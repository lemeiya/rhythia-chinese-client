extends Control

@export var target_bus: String

var updating:bool = false

func update_db(db:float):
	updating = true
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(target_bus),db)
	$percent.value = db_to_linear(db) * 100
	$db.value = db
	updating = false

func update_from_percent(_v=null):
	if !updating:
		print("updating from percent")
		update_db(linear_to_db($percent.value / 100))

func update_from_db(_v=null):
	if !updating:
		print("updating from db")
		update_db($db.value)

func _ready():
	update_db(AudioServer.get_bus_volume_db(AudioServer.get_bus_index(target_bus)))
	$percent.connect("value_changed", Callable(self, "update_from_percent"))
	$db.connect("value_changed", Callable(self, "update_from_db"))
