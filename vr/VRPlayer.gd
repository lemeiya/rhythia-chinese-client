extends Node3D
class_name VRPlayer

@onready var origin:Node3D = $Origin
@onready var head:Camera3D = $Origin/Head
@onready var left_hand:Node3D = $Origin/LeftHand
@onready var left_ray:RayCast3D = $Origin/LeftHand/Ray
@onready var right_hand:Node3D = $Origin/RightHand
@onready var right_ray:RayCast3D = $Origin/RightHand/Ray

var primary_ray:RayCast3D

func update_primary_ray():
	if Rhythia.vr_left_handed:
		primary_ray = left_ray
		left_ray.enabled = true
		right_ray.enabled = false
	else:
		primary_ray = right_ray
		left_ray.enabled = false
		right_ray.enabled = true

func _ready():
	origin.visible = false
	if Rhythia.fake_vr:
		origin = $FakeOrigin
		head = $FakeOrigin/Head
		left_hand = $FakeOrigin/LeftHand
		left_ray = $FakeOrigin/LeftHand/Ray
		right_hand = $FakeOrigin/RightHand
		right_ray = $FakeOrigin/RightHand/Ray
	origin.visible = true
	update_primary_ray()
	set_process(true)
	process_mode = PROCESS_MODE_ALWAYS



func _process(delta):
	if Input.is_action_just_pressed("vr_switch_hands"):
		Rhythia.vr_left_handed = !Rhythia.vr_left_handed
		update_primary_ray()
	primary_ray.force_raycast_update()
	primary_ray.update_beam()
