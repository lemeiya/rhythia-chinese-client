class_name File
extends RefCounted

const READ := FileAccess.READ
const WRITE := FileAccess.WRITE
const READ_WRITE := FileAccess.READ_WRITE
const WRITE_READ := FileAccess.WRITE_READ

const COMPRESSION_FASTLZ := FileAccess.COMPRESSION_FASTLZ
const COMPRESSION_DEFLATE := FileAccess.COMPRESSION_DEFLATE
const COMPRESSION_ZSTD := FileAccess.COMPRESSION_ZSTD
const COMPRESSION_GZIP := FileAccess.COMPRESSION_GZIP

var _file: FileAccess
var _last_error: Error = OK

func open(path: String, flags: int) -> Error:
	_file = FileAccess.open(path, flags)
	_last_error = FileAccess.get_open_error()
	if _file == null and _last_error == OK:
		_last_error = ERR_CANT_OPEN
	return _last_error

func open_compressed(path: String, mode_flags: int, compression_mode: int = COMPRESSION_FASTLZ) -> Error:
	_file = FileAccess.open_compressed(path, mode_flags, compression_mode)
	_last_error = FileAccess.get_open_error()
	if _file == null and _last_error == OK:
		_last_error = ERR_CANT_OPEN
	return _last_error

func close() -> void:
	if _file:
		_file.close()
	_file = null

func is_open() -> bool:
	return _file != null and _file.is_open()

func file_exists(path: String) -> bool:
	return FileAccess.file_exists(path)

func get_error() -> Error:
	return _file.get_error() if _file else _last_error

func get_as_text(skip_cr: bool = false) -> String:
	return _file.get_as_text(skip_cr) if _file else ""

func get_buffer(length: int) -> PackedByteArray:
	return _file.get_buffer(length)

func get_line() -> String:
	return _file.get_line()

func get_8() -> int:
	return _file.get_8()

func get_16() -> int:
	return _file.get_16()

func get_32() -> int:
	return _file.get_32()

func get_64() -> int:
	return _file.get_64()

func get_float() -> float:
	return _file.get_float()

func get_double() -> float:
	return _file.get_double()

func get_var(allow_objects: bool = false):
	return _file.get_var(allow_objects)

func store_string(value: String) -> void:
	_file.store_string(value)

func store_line(value: String) -> void:
	_file.store_line(value)

func store_buffer(value: PackedByteArray) -> void:
	_file.store_buffer(value)

func store_8(value: int) -> void:
	_file.store_8(value)

func store_16(value: int) -> void:
	_file.store_16(value)

func store_32(value: int) -> void:
	_file.store_32(value)

func store_64(value: int) -> void:
	_file.store_64(value)

func store_float(value: float) -> void:
	_file.store_float(value)

func store_double(value: float) -> void:
	_file.store_double(value)

func store_var(value, full_objects: bool = false) -> void:
	_file.store_var(value, full_objects)

func get_position() -> int:
	return _file.get_position()

func get_length() -> int:
	return _file.get_length()

func seek(position: int) -> void:
	_file.seek(position)

func seek_end(position: int = 0) -> void:
	_file.seek_end(position)

func eof_reached() -> bool:
	return _file.eof_reached()

func flush() -> void:
	_file.flush()
