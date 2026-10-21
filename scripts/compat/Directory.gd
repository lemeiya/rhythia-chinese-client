class_name Directory
extends RefCounted

var _dir: DirAccess
var _last_error: Error = OK

func open(path: String) -> Error:
	_dir = DirAccess.open(path)
	_last_error = DirAccess.get_open_error()
	if _dir == null and _last_error == OK:
		_last_error = ERR_CANT_OPEN
	return _last_error

func list_dir_begin(skip_navigational: bool = true, skip_hidden: bool = false) -> Error:
	if not _dir:
		return ERR_UNCONFIGURED
	_dir.include_navigational = not skip_navigational
	_dir.include_hidden = not skip_hidden
	return _dir.list_dir_begin()

func get_next() -> String:
	return _dir.get_next() if _dir else ""

func current_is_dir() -> bool:
	return _dir.current_is_dir() if _dir else false

func list_dir_end() -> void:
	if _dir:
		_dir.list_dir_end()

func change_dir(path: String) -> Error:
	return _dir.change_dir(path) if _dir else ERR_UNCONFIGURED

func get_current_dir() -> String:
	return _dir.get_current_dir() if _dir else ""

func file_exists(path: String) -> bool:
	return _dir.file_exists(path) if _dir else FileAccess.file_exists(path)

func dir_exists(path: String) -> bool:
	return _dir.dir_exists(path) if _dir else DirAccess.dir_exists_absolute(path)

func make_dir(path: String) -> Error:
	return _dir.make_dir(path) if _dir else DirAccess.make_dir_absolute(path)

func make_dir_recursive(path: String) -> Error:
	return _dir.make_dir_recursive(path) if _dir else DirAccess.make_dir_recursive_absolute(path)

func remove(path: String) -> Error:
	return _dir.remove(path) if _dir else DirAccess.remove_absolute(path)

func rename(from: String, to: String) -> Error:
	return _dir.rename(from, to) if _dir else DirAccess.rename_absolute(from, to)

func copy(from: String, to: String) -> Error:
	return _dir.copy(from, to) if _dir else DirAccess.copy_absolute(from, to)

func get_space_left() -> int:
	return _dir.get_space_left() if _dir else 0
