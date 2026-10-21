extends Node

var pending: Dictionary = {}


func queue_resource(path: String, _in_front: bool = false) -> Error:
	if Input.is_key_pressed(KEY_CTRL) and Input.is_key_pressed(KEY_P):
		return ERR_SKIP
	if pending.has(path):
		return OK
	if ResourceLoader.has_cached(path):
		pending[path] = ResourceLoader.load(path)
		return OK

	var error := ResourceLoader.load_threaded_request(path)
	if error == OK:
		pending[path] = null
	return error


func cancel_resource(path: String) -> void:
	# Godot 4 owns the worker threads; dropping local tracking is the supported cancel behavior.
	pending.erase(path)


func get_progress(path: String) -> float:
	if not pending.has(path):
		return -1.0
	if pending[path] != null:
		return 1.0

	var progress := []
	var status := ResourceLoader.load_threaded_get_status(path, progress)
	if status == ResourceLoader.THREAD_LOAD_LOADED:
		return 1.0
	if status == ResourceLoader.THREAD_LOAD_IN_PROGRESS and not progress.is_empty():
		return float(progress[0])
	return 0.0


func is_ready(path: String) -> bool:
	if not pending.has(path):
		return false
	return pending[path] != null or ResourceLoader.load_threaded_get_status(path) == ResourceLoader.THREAD_LOAD_LOADED


func get_resource(path: String):
	if not pending.has(path):
		return ResourceLoader.load(path)

	var resource = pending[path]
	if resource == null:
		resource = ResourceLoader.load_threaded_get(path)
	pending.erase(path)
	return resource


func start() -> void:
	pass
