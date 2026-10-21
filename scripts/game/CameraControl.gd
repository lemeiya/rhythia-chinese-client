# Licensed under the MIT License.
# Copyright (c) 2018-2020 Jaccomo Lorenz (Maujoe)

extends Node3D

# User settings:
# General settings
@export var enabled = false: set = set_enabled

# See https://docs.godotengine.org/en/latest/classes/class_input.html?highlight=Input#enumerations
var inactive_mouse_mode = Input.MOUSE_MODE_HIDDEN
var active_mouse_mode = Input.MOUSE_MODE_CAPTURED

enum Freelook_Modes {MOUSE, INPUT_ACTION, MOUSE_AND_INPUT_ACTION}

# Freelook settings
@export var freelook = true
@export_enum("Mouse", "Input Action", "Mouse and Input Action") var freelook_mode:int = 2
@export_range(0.0, 0.999, 0.001) var smoothness:float = 0.5: set = set_smoothness
@export_range(0, 360, 1) var yaw_limit:int = 360
@export_range(0, 360, 1) var pitch_limit:int = 360

var sensitivity = 0.5

# Pivot Settings
@export var privot:NodePath: set = set_privot
var pivot_node:Node3D
@export var distance = 5.0: set = set_distance
@export var rotate_privot = false
@export var collisions = true: set = set_collisions

# Movement settings
@export var movement = true
@export_range(0.0, 1.0, 0.001) var acceleration:float = 1.0
@export_range(0.0, 1.0, 0.001) var deceleration:float = 0.1
@export var max_speed = Vector3(5.0, 5.0, 5.0)
@export var local = true

# Input Actions
@export var rotate_left_action = "ui_left"
@export var rotate_right_action = "ui_right"
@export var rotate_up_action = "ui_up"
@export var rotate_down_action = "ui_down"
@export var forward_action = "fc_front"
@export var backward_action = "fc_back"
@export var left_action = "fc_left"
@export var right_action = "fc_right"
@export var up_action = "fc_up"
@export var down_action = "fc_down"
@export var trigger_action = "fc_trigger"

# Gui settings
@export var use_gui = true
@export var gui_action = "pause"

# Intern variables.
var _mouse_offset = Vector2()
var _rotation_offset = Vector2()
var _yaw = 0.0
var _pitch = 0.0
var _total_yaw = 0.0
var _total_pitch = 0.0

var _direction = Vector3(0.0, 0.0, 0.0)
var _speed = Vector3(0.0, 0.0, 0.0)
var _gui

var _triggered=false

const ROTATION_MULTIPLIER = 500

func _ready():
	_check_actions([
		forward_action,
		backward_action,
		left_action,
		right_action,
		gui_action,
		up_action,
		down_action,
		rotate_left_action,
		rotate_right_action,
		rotate_up_action,
		rotate_down_action
	])

	if not privot.is_empty():
		pivot_node = get_node_or_null(privot) as Node3D
	
#	set_enabled(enabled)

func _input(event):
		if len(trigger_action)!=0:
			if event.is_action_pressed(trigger_action):
				_triggered=true
				Input.set_mouse_mode(active_mouse_mode)
			elif event.is_action_released(trigger_action):
				Input.set_mouse_mode(inactive_mouse_mode)
				_triggered=false
		else:
			_triggered=true
		if freelook:
			if _triggered and event is InputEventMouseMotion:
				_mouse_offset = event.relative
				
			_rotation_offset.x = Input.get_action_strength(rotate_right_action) - Input.get_action_strength(rotate_left_action)
			_rotation_offset.y = Input.get_action_strength(rotate_down_action) - Input.get_action_strength(rotate_up_action)
	
		if movement:
			_direction.x = Input.get_action_strength(right_action) - Input.get_action_strength(left_action)
			_direction.y = Input.get_action_strength(up_action) - Input.get_action_strength(down_action)
			_direction.z = Input.get_action_strength(backward_action) - Input.get_action_strength(forward_action)

func _process(delta):
	if _triggered:
		_update_views(delta)

func _update_views(delta):
	if pivot_node:
		_update_distance()
	if freelook:
		_update_rotation(delta)
	if movement:
		_update_movement(delta)

func _physics_process(delta):
	if _triggered:
		_update_views_physics(delta)

func _update_views_physics(delta):
	# Called when collision are enabled
	_update_distance()
	if freelook:
		_update_rotation(delta)

	var space_state = get_world_3d().get_direct_space_state()
	var query := PhysicsRayQueryParameters3D.create(pivot_node.global_position, global_position)
	var obstacle = space_state.intersect_ray(query)
	if not obstacle.is_empty():
		set_position(obstacle.position)

func _update_movement(delta):
	var offset = max_speed * acceleration * _direction

	_speed.x = clamp(_speed.x + offset.x, -max_speed.x, max_speed.x)
	_speed.y = clamp(_speed.y + offset.y, -max_speed.y, max_speed.y)
	_speed.z = clamp(_speed.z + offset.z, -max_speed.z, max_speed.z)

	# Apply deceleration if no input
	if _direction.x == 0:
		_speed.x *= (1.0 - deceleration)
	if _direction.y == 0:
		_speed.y *= (1.0 - deceleration)
	if _direction.z == 0:
		_speed.z *= (1.0 - deceleration)

	if local:
		translate(_speed * delta)
	else:
		global_translate(_speed * delta)

func _update_rotation(delta):
	var offset = Vector2();
	
	if not freelook_mode == Freelook_Modes.INPUT_ACTION:
		offset += _mouse_offset * sensitivity * Rhythia.sensitivity
	if not freelook_mode == Freelook_Modes.MOUSE: 
		offset += _rotation_offset * sensitivity * Rhythia.sensitivity * ROTATION_MULTIPLIER * delta
	
	_mouse_offset = Vector2()

	_yaw = _yaw * smoothness + offset.x * (1.0 - smoothness)
	_pitch = _pitch * smoothness + offset.y * (1.0 - smoothness)

	if yaw_limit < 360:
		_yaw = clamp(_yaw, -yaw_limit - _total_yaw, yaw_limit - _total_yaw)
	if pitch_limit < 360:
		_pitch = clamp(_pitch, -pitch_limit - _total_pitch, pitch_limit - _total_pitch)

	_total_yaw += _yaw
	_total_pitch += _pitch

	if pivot_node:
		var target = pivot_node.global_position
		var dist = get_position().distance_to(target)

		set_position(target)
		rotate_y(deg_to_rad(-_yaw))
		rotate_object_local(Vector3(1,0,0), deg_to_rad(-_pitch))
		translate(Vector3(0.0, 0.0, dist))

		if rotate_privot:
			pivot_node.rotate_y(deg_to_rad(-_yaw))
	else:
		rotate_y(deg_to_rad(-_yaw))
		rotate_object_local(Vector3(1,0,0), deg_to_rad(-_pitch))

func _update_distance():
	var t = pivot_node.global_position
	t.z -= distance
	set_position(t)

func _update_process_func():
	# Use physics process if collision are enabled
	if collisions and pivot_node:
		set_physics_process(true)
		set_process(false)
	else:
		set_physics_process(false)
		set_process(true)

func _check_actions(actions=[]):
	if OS.is_debug_build():
		for action in actions:
			if not InputMap.has_action(action):
				print('WARNING: No action "' + action + '"')

func set_privot(value):
	privot = value
	if is_inside_tree() and not privot.is_empty():
		pivot_node = get_node_or_null(privot) as Node3D
	_update_process_func()
	if len(trigger_action)!=0:
		_update_views(0)

func set_collisions(value):
	collisions = value
	_update_process_func()

var already_loaded_gui:bool = false
func set_enabled(value):
	enabled = value
	if enabled:
		Input.set_mouse_mode(inactive_mouse_mode)
		set_process_input(true)
		_update_process_func()
		if use_gui and !already_loaded_gui:
			if get_parent():
				get_parent().move_child(self, get_parent().get_child_count() - 1)
			already_loaded_gui = true
			_gui = preload("camera_control_gui.gd")
			_gui = _gui.new(self, gui_action)
			add_child(_gui)
	else:
		set_process(false)
		set_process_input(false)
		set_physics_process(false)

func set_smoothness(value):
	smoothness = clamp(value, 0.001, 0.999)

func set_distance(value):
	distance = max(0, value)
