extends Node

# Architecture-independent compatibility API. Rich presence is optional and disabled
# until a Godot 4 GDExtension with both Windows architectures is supplied.

enum Result {
	Ok = 0,
	InternalError = 4,
}

enum ActivityType {
	Playing = 0,
	Streaming = 1,
	Listening = 2,
	Watching = 3,
}

enum ActivityActionType {
	Join = 1,
	Spectate = 2,
}

enum LobbyType {
	Private = 1,
	Public = 2,
}


class ResultData extends RefCounted:
	var result: int = Result.Ok
	var data := StubData.new()


class StubData extends RefCounted:
	func get_id() -> int: return 0


class Core extends RefCounted:
	signal log(message)


class AsyncResult extends RefCounted:
	signal result(value)

	func _init() -> void:
		call_deferred("_complete")

	func _complete() -> void:
		result.emit(ResultData.new())


class ActivityAssets extends RefCounted:
	func set_large_image(_value: String) -> void: pass
	func set_large_text(_value: String) -> void: pass
	func set_small_image(_value: String) -> void: pass
	func set_small_text(_value: String) -> void: pass


class ActivityTimestamps extends RefCounted:
	func set_start(_value: int) -> void: pass
	func set_end(_value: int) -> void: pass


class ActivitySecrets extends RefCounted:
	func set_join(_value: String) -> void: pass


class ActivityParty extends RefCounted:
	func set_id(_value: String) -> void: pass


class Activity extends RefCounted:
	var assets := ActivityAssets.new()
	var timestamps := ActivityTimestamps.new()
	var secrets := ActivitySecrets.new()
	var party := ActivityParty.new()

	func set_type(_value: int) -> void: pass
	func set_application_id(_value: int) -> void: pass
	func set_name(_value: String) -> void: pass
	func set_state(_value: String) -> void: pass
	func set_details(_value: String) -> void: pass
	func get_assets() -> ActivityAssets: return assets
	func get_timestamps() -> ActivityTimestamps: return timestamps
	func get_secrets() -> ActivitySecrets: return secrets
	func get_party() -> ActivityParty: return party


class LobbyTransaction extends RefCounted:
	func set_type(_value: int) -> int: return Result.Ok
	func set_owner(_value: int) -> int: return Result.Ok
	func set_capacity(_value: int) -> int: return Result.Ok
	func set_metadata(_key: String, _value: String) -> int: return Result.Ok
	func delete_metadata(_key: String) -> int: return Result.Ok
	func set_locked(_value: bool) -> int: return Result.Ok


class ActivityManager extends RefCounted:
	signal activity_join(secret)
	signal activity_invite
	signal activity_join_request

	func register_command(_command: String) -> int: return Result.Ok
	func clear_activity() -> AsyncResult: return AsyncResult.new()
	func update_activity(_activity: Activity) -> AsyncResult: return AsyncResult.new()


class LobbyManager extends RefCounted:
	signal lobby_message(lobby_id, user_id, message)
	signal member_connect(lobby_id, user_id)

	func connect_lobby_with_activity_secret(_secret: String) -> AsyncResult: return AsyncResult.new()
	func get_lobby_create_transaction() -> LobbyTransaction: return LobbyTransaction.new()
	func create_lobby(_transaction: LobbyTransaction) -> AsyncResult: return AsyncResult.new()
	func send_lobby_message(_lobby_id: int, _message: String) -> AsyncResult: return AsyncResult.new()
	func get_member_count(_lobby_id: int) -> int: return 0
	func get_all_member_users(_lobby_id: int) -> Array: return []


class OverlayManager extends RefCounted:
	func open_activity_invite(_activation_type: int) -> AsyncResult: return AsyncResult.new()


var activity_manager := ActivityManager.new()
var lobby_manager := LobbyManager.new()
var overlay_manager := OverlayManager.new()
var discore_core_ := Core.new()
