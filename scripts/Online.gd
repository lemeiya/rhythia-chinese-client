extends Node

# https://cdn.rhythia.net/index.json

var mapdb_api:String = ""
var community_map_api:String = ""

var map_registry:Registry

signal db_maps_done
signal map_downloaded

signal _httpreq_finished

var mapdl_hr:HTTPRequest = HTTPRequest.new()
var mapdl_bs:float = 1
var mapdl_bd:float = 0

signal _mapdl_req
func _on_mapdl_request_completed(result:int,response_code:int,headers:PackedStringArray,body:PackedByteArray):
	emit_signal("_mapdl_req",{result=result,response_code=response_code,headers=headers,body=body})

func cancel():
	mapdl_hr.cancel_request()
	emit_signal("_mapdl_req",{result=-1})

func mapdl_error(id:String,error:String,map:Song):
	print("[MapDB Download] Map %s errored with code %s" % [map.id,error])
	emit_signal("map_downloaded",{id=id, success=false, error=error})

func _process(_d):
	mapdl_bs = mapdl_hr.get_body_size()
	mapdl_bd = mapdl_hr.get_downloaded_bytes()

signal _connection_test
var ctest_hr:HTTPRequest = HTTPRequest.new()
func _on_ctest_request_completed(result:int,response_code:int,headers:PackedStringArray,body:PackedByteArray):
	if result == HTTPRequest.RESULT_SUCCESS:
		emit_signal("_connection_test",true)
	else:
		emit_signal("_connection_test",false)

func test_connection():
	var res = ctest_hr.request(ProjectSettings.get_setting("application/networking/test_url"))
	if res != OK: emit_signal("_connection_test",false)

func _mapdl_handler(id:String,map:Song):
	print("[MapDB Download] Starting download of map %s" % map.id)
	if !ProjectSettings.get_setting("application/networking/enabled"):
		mapdl_error(id,"Networking is disabled",map); return
	if mapdb_api == "":
		mapdl_error(id,"MapDB API Invalid",map); return
	if !Globals.is_valid_url(mapdb_api):
		mapdl_error(id,"MapDB API Invalid",map); return
	
	call_deferred("test_connection")
	if !await self._connection_test:
		mapdl_error(id,"Failed to connect",map); return
	
	var dir:Directory = Directory.new()
	if dir.file_exists(Globals.p("user://mapdl.sspm.part")):
		dir.remove(Globals.p("user://mapdl.sspm.part"))
	
	mapdl_hr.download_file = Globals.p("user://mapdl.sspm.part")
	var res = mapdl_hr.request(map.download_url)
	if res != OK:
		if res == ERR_INVALID_PARAMETER: mapdl_error(id,"Invalid Parameter",map)
		elif res == ERR_CANT_CONNECT: mapdl_error(id,"Can't Connect",map)
		else: mapdl_error(id,"Unknown Error (%s)" % res,map)
	else:
		var mapdl_res = await self._mapdl_req
		
		if mapdl_res.result == HTTPRequest.RESULT_CANT_RESOLVE:
			mapdl_error(id,"Can't Resolve",map)
		elif mapdl_res.result == HTTPRequest.RESULT_CANT_CONNECT:
			mapdl_error(id,"Can't Connect",map)
		elif mapdl_res.result == HTTPRequest.RESULT_CONNECTION_ERROR:
			mapdl_error(id,"Connection Error",map)
		elif mapdl_res.result == HTTPRequest.RESULT_TLS_HANDSHAKE_ERROR:
			mapdl_error(id,"SSL Handshake Error",map)
		elif mapdl_res.result == HTTPRequest.RESULT_TIMEOUT:
			mapdl_error(id,"Timeout",map)
		elif mapdl_res.result == HTTPRequest.RESULT_REDIRECT_LIMIT_REACHED:
			mapdl_error(id,"Redirect Limit Reached",map)
		elif mapdl_res.result == HTTPRequest.RESULT_DOWNLOAD_FILE_CANT_OPEN:
			mapdl_error(id,"Download File Open Error",map)
		elif mapdl_res.result == HTTPRequest.RESULT_DOWNLOAD_FILE_WRITE_ERROR:
			mapdl_error(id,"Download File Write Error",map)
			
		elif mapdl_res.result == HTTPRequest.RESULT_SUCCESS:
			if mapdl_res.response_code == 200:
				var target_path = Globals.p("user://maps/%s.sspm" % map.id)
				if dir.file_exists(target_path):
					dir.remove(target_path)
				var rename_error = dir.rename(Globals.p("user://mapdl.sspm.part"), target_path)
				if rename_error != OK:
					mapdl_error(id, "Map Save Error (%s)" % rename_error, map)
					return
				var load_result = map.load_from_sspm(target_path)
				if load_result is String:
					mapdl_error(id, "Map Load Error: %s" % load_result, map)
					return
				if map.songType != Globals.MAP_SSPM2:
					if Input.is_action_pressed("skip_convert"):
						Globals.notify(
							Globals.NOTIFY_WARN,
							"Not converting to SSPMv2 as Ctrl+M was held.",
							"Skip Conversion"
						)
					else:
						map.convert_to_sspm(true)
				var reload_result = map.load_from_sspm(target_path)
				if reload_result is String:
					mapdl_error(id, "Map Load Error: %s" % reload_result, map)
					return
				emit_signal("map_downloaded",{id=id, success=true})
			else:
				var test_json_conv = JSON.new()
				test_json_conv.parse(mapdl_res.body.get_string_from_utf8())
				var resp = test_json_conv.get_data()
				if resp: mapdl_error(id, resp.error, map)
				else: mapdl_error(id, "HTTP-%s" % mapdl_res.response_code, map)
		elif mapdl_res.result == -1: # canceled
			mapdl_error(id,"Cancelled", map)
		else: # Unknown error
			mapdl_error(id,"Unknown Error", map)


func download_map(map:Song):
	var id = v4()
	call_deferred("_mapdl_handler",id,map)
	return id


var netmaps_hr:HTTPRequest = HTTPRequest.new()
signal _netmaps_req
func _on_netmaps_request_completed(result:int,response_code:int,headers:PackedStringArray,body:PackedByteArray):
	emit_signal("_netmaps_req",{result=result,response_code=response_code,headers=headers,body=body})

var community_maps_hr:HTTPRequest = HTTPRequest.new()
signal _community_maps_req
func _on_community_maps_request_completed(result:int,response_code:int,headers:PackedStringArray,body:PackedByteArray):
	emit_signal("_community_maps_req",{result=result,response_code=response_code,headers=headers,body=body})

func _import_community_maps(netmaps:Dictionary):
	var i = 0
	var frame_interval = max(1, int(floor(float(netmaps.size()) / 100.0)))
	for id in netmaps.keys():
		if !map_registry.idx_id.has(id):
			var song:Song = Song.new()
			var map_data:Dictionary = netmaps[id].duplicate(true) if netmaps[id] is Dictionary else {}
			var community_api = String(ProjectSettings.get_setting("application/networking/community_api", "")).trim_suffix("/")
			if community_api != "":
				map_data.download = community_api + "/maps/" + String(id) + "/download"
			var result:Dictionary = song.load_from_db_data(map_data)
			if result.success:
				song.source_id = "community"
				map_registry.add_item(song)
			else:
				print("[Community Map Import] Map %s errored with code %s" % [id,result.error])
		i += 1
		if i % frame_interval == 0:
			await get_tree().process_frame

func _load_community_cache() -> Dictionary:
	var file:File = File.new()
	if !file.file_exists(Globals.p("user://.community_mapdb_cache.json")):
		return {}
	if file.open(Globals.p("user://.community_mapdb_cache.json"), File.READ) != OK:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	return parsed if parsed is Dictionary else {}

func load_community_maps():
	if !ProjectSettings.get_setting("application/networking/enabled"):
		return
	if community_map_api == "" or !Globals.is_valid_url(community_map_api):
		return
	var request_error = community_maps_hr.request(community_map_api)
	if request_error != OK:
		await _import_community_maps(_load_community_cache())
		return
	var response = await self._community_maps_req
	var netmaps:Dictionary = {}
	if response.result == HTTPRequest.RESULT_SUCCESS and response.response_code == 200:
		var parsed = JSON.parse_string(response.body.get_string_from_utf8())
		if parsed is Dictionary:
			netmaps = parsed
			var file:File = File.new()
			if file.open(Globals.p("user://.community_mapdb_cache.json"), File.WRITE) == OK:
				file.store_buffer(response.body)
			file.close()
	if netmaps.is_empty():
		netmaps = _load_community_cache()
		if netmaps.is_empty():
			Globals.notify(Globals.NOTIFY_WARN, "Community maps could not be loaded.", "Community Maps")
			return
	await _import_community_maps(netmaps)

const weekday = [
	"Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"
]
const month = [
	"Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
]

func load_db_maps():
	await get_tree().process_frame
	
	if !ProjectSettings.get_setting("application/networking/enabled"):
		pass # 011-865
	elif mapdb_api == "" || mapdb_api.begins_with("http://localhost") && !OS.has_feature("debug"):
		show_db_error("Map database is improperly configured.","Map Database Error")
		await self.error_done
	elif !Globals.is_valid_url(mapdb_api):
		show_db_error("Map database download failed.\nMapDB URL Invalid","Map Database Error")
		await self.error_done
	else:
		call_deferred("test_connection")
		if !await self._connection_test:
			Globals.notify(
				Globals.NOTIFY_ERROR,
				"Online maps will not be loaded - failed to connect to map database.\n\nMake sure your system clock is Synchronized!",
				"No Connection"
			)
			await load_community_maps()
			emit_signal("db_maps_done")
			return
		
		var netmaps:Dictionary = {
			"id_that_doesnt_exist": JSON.parse_string("""{
				"id":"id_that_doesnt_exist",
				"download":"http://chedski.test/ssp/mapdb/api/download/id_that_doesnt_exist",
				"audio":"http://chedski.test/ssp/mapdb/api/audio/id_that_doesnt_exist",
				"cover":null,
				"version":1,
				"name":"000000 net test map",
				"song":"Waterflame - Geometrical Dominator",
				"author":["Azurlexx"],
				"difficulty":-1,
				"difficulty_name":"LOGIC?",
				"stars":-1,
				"length_ms":96846,
				"note_count":384,
				"has_cover":false,
				"broken":false,
				"tags":["ss_archive"],
				"content_warnings":[],
				"note_data_offset":1594212,
				"note_data_length":2688,
				"music_format":"mp3",
				"music_offset":117,
				"music_length":1594095 }""")
		}
		
		var file:File = File.new()
		var dict_date = Time.get_datetime_dict_from_unix_time(1373) # first number that came to mind
		
		if file.file_exists(Globals.p("user://.mapdb_cache.json")) && file.file_exists(Globals.p("user://.mapdb_updated.txt")):
			var err = file.open(Globals.p("user://.mapdb_updated.txt"),File.READ)
			if err == OK:
				dict_date = Time.get_datetime_dict_from_datetime_string(file.get_as_text(), true)
			file.close()

		netmaps_hr.request(mapdb_api, PackedStringArray([
			"If-Modified-Since: %s, %02d %s %04d %02d:%02d:%02d GMT" % [
				weekday[dict_date.weekday],
				dict_date.day, month[dict_date.month - 1], dict_date.year,
				dict_date.hour, dict_date.minute, dict_date.second
			]
		]))
		var netmaps_res = await self._netmaps_req
		
		
		
		if netmaps_res.result == HTTPRequest.RESULT_CANT_RESOLVE:
			show_db_error("Map database download failed.\nError: Can't Resolve","Map Database Error")
			await self.error_done
		elif netmaps_res.result == HTTPRequest.RESULT_CANT_CONNECT:
			show_db_error("Map database download failed.\nError: Can't Connect","Map Database Error")
			await self.error_done
		elif netmaps_res.result == HTTPRequest.RESULT_CONNECTION_ERROR:
			show_db_error("Map database download failed.\nError: Connection Error","Map Database Error")
			await self.error_done
		elif netmaps_res.result == HTTPRequest.RESULT_TLS_HANDSHAKE_ERROR:
			show_db_error("Map database download failed.\nError: SSL Handshake Error","Map Database Error")
			await self.error_done
		elif netmaps_res.result == HTTPRequest.RESULT_TIMEOUT:
			show_db_error("Map database download failed.\nError: Timeout","Map Database Error")
			await self.error_done
		elif netmaps_res.result == HTTPRequest.RESULT_REDIRECT_LIMIT_REACHED:
			show_db_error("Map database download failed.\nError: Redirect Limit Reached","Map Database Error")
			await self.error_done
			
		elif netmaps_res.result == HTTPRequest.RESULT_SUCCESS:
			if netmaps_res.response_code == 200:
				print("Cache miss!")
				var res = file.open(Globals.p("user://.mapdb_cache.json"),File.WRITE)
				if res == OK:
					file.store_buffer(netmaps_res.body)
				file.close()
				if res == OK:
					res = file.open(Globals.p("user://.mapdb_updated.txt"),File.WRITE)
					if res == OK:
						file.store_string(Time.get_datetime_string_from_system(true))
					file.close()
				
				var test_json_conv = JSON.new()
				test_json_conv.parse(netmaps_res.body.get_string_from_utf8())
				var nmp = test_json_conv.get_data()
				if !(nmp is Dictionary):
					show_db_error("Map database download failed.\nError: Malformed JSON","Map Database Error")
					await self.error_done
				else:
					netmaps = nmp
					var i = 0
					for id in netmaps.keys():
						if !map_registry.idx_id.has(id):
							var song:Song = Song.new()
							var result:Dictionary = song.load_from_db_data(netmaps[id])
							
							if result.success:
								song.source_id = "official"
								map_registry.add_item(song)
							else:
								print("[MapDB Import] Map %s errored with code %s" % [id,result.error])
								Globals.notify(
									Globals.NOTIFY_ERROR,
									"map %s errored\nError code: %s" % [id,result.error],
									"Map Database Import"
								)
							
							i += 1
							if fmod(i,floor(float(netmaps.size())/100)) == 0: await get_tree().process_frame
			elif netmaps_res.response_code == 304:
				print("Cache hit!")
				var res = file.open(Globals.p("user://.mapdb_cache.json"),File.READ)
				if res == OK:
					var test_json_conv = JSON.new()
					test_json_conv.parse(file.get_as_text())
					var nmp = test_json_conv.get_data()
					if !(nmp is Dictionary):
						var dir:Directory = Directory.new()
						dir.remove(Globals.p("user://.mapdb_cache.json"))
						dir.remove(Globals.p("user://.mapdb_updated.txt"))
					else:
						netmaps = nmp
						var i = 0
						for id in netmaps.keys():
							if !map_registry.idx_id.has(id):
								var song:Song = Song.new()
								var result:Dictionary = song.load_from_db_data(netmaps[id])
								
								if result.success:
									song.source_id = "official"
									map_registry.add_item(song)
								else:
									print("[MapDB Import] Map %s errored with code %s" % [id,result.error])
									Globals.notify(
										Globals.NOTIFY_ERROR,
										"map %s errored\nError code: %s" % [id,result.error],
										"Map Database Import"
									)
								
								i += 1
								if fmod(i,floor(float(netmaps.size())/100)) == 0: await get_tree().process_frame
				file.close()
			else:
				show_db_error("Map database download failed.\nError code: HTTP-%s" % netmaps_res.response_code,"Map Database Error")
				await self.error_done
		else: # Unknown error
			show_db_error("Map database download failed.\nError code: HTTP-%s" % netmaps_res.response_code,"Map Database Error")
			await self.error_done
			
	
	await load_community_maps()
	emit_signal("db_maps_done")

var latest_version_data
signal latest_version
var version_hr:HTTPRequest = HTTPRequest.new()
func check_latest_version():
	if !(OS.has_feature("Windows") or OS.has_feature("X11")) or !ProjectSettings.get_setting("application/networking/enabled"):
		emit_signal("latest_version",ProjectSettings.get_setting("application/config/version"))
		return
	var github_url = "https://api.github.com/repos/%s/releases/latest"
	version_hr.request(github_url % ProjectSettings.get_setting("application/networking/github_repo"))
func _on_version_request_completed(result:int,response_code:int,headers:PackedStringArray,body:PackedByteArray):
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		emit_signal("latest_version",ProjectSettings.get_setting("application/config/version"))
		return
	var string = body.get_string_from_utf8()
	var test_json_conv = JSON.new()
	var parse_error = test_json_conv.parse(string)
	var json = test_json_conv.get_data()
	if parse_error != OK or not json is Dictionary:
		emit_signal("latest_version",ProjectSettings.get_setting("application/config/version"))
		return
	var data = json
	latest_version_data = data
	emit_signal("latest_version",data.tag_name)
signal update_finished
signal _update_req
var update_hr:HTTPRequest = HTTPRequest.new()
func attempt_update():
	var asset
	var asset_name = "windows.zip"
	if OS.has_feature("X11"): asset_name = "linux.zip"
	for _asset in latest_version_data.assets:
		if _asset.name == asset_name:
			asset = _asset
			break
	if !asset:
		emit_signal("update_finished")
		return
	var exec_dir = OS.get_executable_path().get_base_dir()
	var file_path = exec_dir.path_join("update.zip")
	update_hr.download_file = file_path
	update_hr.request(asset.url,["Accept: application/octet-stream"])
	var res = await self._update_req
	if res[0] != HTTPRequest.RESULT_SUCCESS or res[1] != 200:
		emit_signal("update_finished")
		return
	print("Extracting")
	ProjectSettings.load_resource_pack(file_path,false)
	var read_file = File.new()
	read_file.open("res://SoundSpacePlus.pck",File.READ)
	var new_file_buffer = read_file.get_buffer(read_file.get_length())
	read_file.close()
	var file = File.new()
	var dir = Directory.new()
	if dir.file_exists(exec_dir.path_join("SoundSpacePlus.pck.old")):
		dir.remove(exec_dir.path_join("SoundSpacePlus.pck.old"))
	if dir.file_exists(exec_dir.path_join("SoundSpacePlus.pck")):
		dir.rename(exec_dir.path_join("SoundSpacePlus.pck"),exec_dir.path_join("SoundSpacePlus.pck.old"))
	file.open(exec_dir.path_join("SoundSpacePlus.pck"),File.WRITE)
	file.store_buffer(new_file_buffer)
	file.close()
	emit_signal("update_finished")
func _on_update_request_completed(result:int,response_code:int,headers:PackedStringArray,body:PackedByteArray):
	emit_signal("_update_req",[result,response_code])

func _ready():
	add_child(netmaps_hr)
	netmaps_hr.use_threads = true
	netmaps_hr.timeout = 80
	netmaps_hr.connect("request_completed", Callable(self, "_on_netmaps_request_completed"))

	add_child(community_maps_hr)
	community_maps_hr.use_threads = true
	community_maps_hr.timeout = 30
	community_maps_hr.connect("request_completed", Callable(self, "_on_community_maps_request_completed"))
	
	add_child(ctest_hr)
	ctest_hr.use_threads = true
	ctest_hr.timeout = 5
	ctest_hr.connect("request_completed", Callable(self, "_on_ctest_request_completed"))
	
	add_child(mapdl_hr)
	mapdl_hr.use_threads = false
	mapdl_hr.timeout = 0
	mapdl_hr.connect("request_completed", Callable(self, "_on_mapdl_request_completed"))
	
	add_child(version_hr)
	version_hr.use_threads = true
	version_hr.timeout = 5
	version_hr.connect("request_completed", Callable(self, "_on_version_request_completed"))
	
	add_child(update_hr)
	update_hr.use_threads = true
	update_hr.timeout = 0
	update_hr.connect("request_completed", Callable(self, "_on_update_request_completed"))
	
	process_mode = PROCESS_MODE_ALWAYS
	
	mapdb_api = ProjectSettings.get_setting("application/networking/mapdb_api")
	community_map_api = String(ProjectSettings.get_setting("application/networking/community_map_api", ""))
	if community_map_api == "":
		var community_api = String(ProjectSettings.get_setting("application/networking/community_api", "")).trim_suffix("/")
		if community_api != "":
			community_map_api = community_api + "/maps/index"

signal error_done
func show_db_error(body:String,title:String):
	# Globals.notify(Globals.NOTIFY_ERROR,title,body)
	Globals.confirm_prompt.s_alert.play()
	Globals.confirm_prompt.open(body,title,[{text="OK"}])
	await Globals.confirm_prompt.option_selected
	Globals.confirm_prompt.s_back.play()
	Globals.confirm_prompt.close()
	await Globals.confirm_prompt.done_closing
	emit_signal("error_done")

const MODULO_8_BIT = 256

static func getRandomInt():
	# Randomize every time to minimize the risk of collisions
	randomize()

	return randi() % MODULO_8_BIT

static func uuidbin():
	# 16 random bytes with the bytes on index 6 and 8 modified
	return [
		getRandomInt(), getRandomInt(), getRandomInt(), getRandomInt(),
		getRandomInt(), getRandomInt(), ((getRandomInt()) & 0x0f) | 0x40, getRandomInt(),
		((getRandomInt()) & 0x3f) | 0x80, getRandomInt(), getRandomInt(), getRandomInt(),
		getRandomInt(), getRandomInt(), getRandomInt(), getRandomInt(),
	]

static func v4():
	# 16 random bytes with the bytes on index 6 and 8 modified
	var b = uuidbin()

	return '%02x%02x%02x%02x-%02x%02x-%02x%02x-%02x%02x-%02x%02x%02x%02x%02x%02x' % [
		# low
		b[0], b[1], b[2], b[3],
		# mid
		b[4], b[5],
		# hi
		b[6], b[7],
		# clock
		b[8], b[9],
		# clock
		b[10], b[11], b[12], b[13], b[14], b[15]
	]
