extends Node

signal auth_changed

var api_base:String = ""
var token:String = ""
var current_user:Dictionary = {}

func _ready():
	api_base = String(ProjectSettings.get_setting("application/networking/community_api", "")).trim_suffix("/")
	_load_session()

func is_configured() -> bool:
	return api_base != "" and Globals.is_valid_url(api_base)

func is_logged_in() -> bool:
	return token != "" and !current_user.is_empty()

func register(username:String, display_name:String, password:String) -> Dictionary:
	var response = await _request(HTTPClient.METHOD_POST, "/auth/register", {
		username = username,
		display_name = display_name,
		password = password
	})
	if response.get("ok", false):
		token = response.get("token", "")
		current_user = response.get("user", {})
		_save_session()
		emit_signal("auth_changed")
	return response

func login(username:String, password:String) -> Dictionary:
	var response = await _request(HTTPClient.METHOD_POST, "/auth/login", {
		username = username,
		password = password
	})
	if response.get("ok", false):
		token = response.get("token", "")
		current_user = response.get("user", {})
		_save_session()
		emit_signal("auth_changed")
	return response

func logout():
	if token != "":
		await _request(HTTPClient.METHOD_POST, "/auth/logout")
	token = ""
	current_user = {}
	_save_session()
	emit_signal("auth_changed")

func refresh_user() -> Dictionary:
	if token == "":
		return {ok=false, error={message="Not logged in"}}
	var response = await _request(HTTPClient.METHOD_GET, "/users/me")
	if response.get("ok", false):
		current_user = response.get("user", {})
		_save_session()
	else:
		token = ""
		current_user = {}
		_save_session()
		emit_signal("auth_changed")
	return response

func get_home() -> Dictionary:
	return await _request(HTTPClient.METHOD_GET, "/community/home")

func get_posts(page:int=1, limit:int=30) -> Dictionary:
	return await _request(HTTPClient.METHOD_GET, "/posts?page=%d&limit=%d" % [page, limit])

func create_post(title:String, body:String) -> Dictionary:
	return await _request(HTTPClient.METHOD_POST, "/posts", {title=title, body=body})

func get_comments(target_type:String, target_id:String) -> Dictionary:
	return await _request(HTTPClient.METHOD_GET, "/%s/%s/comments" % [target_type, target_id])

func create_comment(target_type:String, target_id:String, body:String) -> Dictionary:
	return await _request(HTTPClient.METHOD_POST, "/%s/%s/comments" % [target_type, target_id], {body=body})

func get_maps(page:int=1, limit:int=30, query:String="", difficulty:int=-2, sort:String="newest") -> Dictionary:
	var path = "/maps?page=%d&limit=%d&sort=%s" % [page, limit, sort]
	if query != "":
		path += "&q=" + query.uri_encode()
	if difficulty >= -1:
		path += "&difficulty=%d" % difficulty
	return await _request(HTTPClient.METHOD_GET, path)

func get_my_posts() -> Dictionary:
	return await _request(HTTPClient.METHOD_GET, "/users/me/posts")

func get_my_maps() -> Dictionary:
	return await _request(HTTPClient.METHOD_GET, "/users/me/maps")

func delete_post(post_id) -> Dictionary:
	return await _request(HTTPClient.METHOD_DELETE, "/posts/%s" % String(post_id))

func toggle_post_like(post_id) -> Dictionary:
	return await _request(HTTPClient.METHOD_POST, "/posts/%s/like" % String(post_id))

func report(target_type:String, target_id:String, reason:String, details:String="") -> Dictionary:
	return await _request(HTTPClient.METHOD_POST, "/reports", {
		target_type = target_type,
		target_id = target_id,
		reason = reason,
		details = details
	})

func _request(method:int, path:String, data:Dictionary={}) -> Dictionary:
	if !is_configured():
		return {ok=false, error={code="not_configured", message="Community API is not configured"}}
	var http = HTTPRequest.new()
	http.use_threads = true
	http.timeout = 20
	add_child(http)
	var headers = PackedStringArray(["Accept: application/json"])
	if token != "":
		headers.append("Authorization: Bearer %s" % token)
	var body = ""
	if !data.is_empty():
		headers.append("Content-Type: application/json")
		body = JSON.stringify(data)
	var err = http.request(api_base + path, headers, method, body)
	if err != OK:
		http.queue_free()
		return {ok=false, error={code="request_failed", message="Request could not be started (%s)" % err}}
	var raw = await http.request_completed
	http.queue_free()
	var result:int = raw[0]
	var response_code:int = raw[1]
	var response_body:PackedByteArray = raw[3]
	if result != HTTPRequest.RESULT_SUCCESS:
		return {ok=false, error={code="network_error", message="Network error (%s)" % result}}
	var text = response_body.get_string_from_utf8()
	var parsed = JSON.parse_string(text) if text != "" else {ok=response_code >= 200 and response_code < 300}
	if !(parsed is Dictionary):
		return {ok=false, error={code="invalid_response", message="Community returned invalid JSON"}}
	if response_code < 200 or response_code >= 300:
		parsed.ok = false
		if !parsed.has("error"):
			parsed.error = {code="http_error", message="HTTP %s" % response_code}
	return parsed

func _session_path() -> String:
	return Globals.p("user://community_session.json")

func _load_session():
	var file = File.new()
	if !file.file_exists(_session_path()):
		return
	if file.open(_session_path(), File.READ) != OK:
		return
	var data = JSON.parse_string(file.get_as_text())
	file.close()
	if data is Dictionary:
		token = String(data.get("token", ""))
		current_user = data.get("user", {}) if data.get("user", {}) is Dictionary else {}

func _save_session():
	var file = File.new()
	if file.open(_session_path(), File.WRITE) != OK:
		return
	file.store_string(JSON.stringify({token=token, user=current_user}))
	file.close()

