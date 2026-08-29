extends Node2D

const SAVE_FILE_PATH = "user://save_game.save"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	get_tree().auto_accept_quit = false
	load_game()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_on_game_quit()
		
func _on_game_quit():
	save_all()
	get_tree().quit()
	
func save_all():
	var save_file = FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	var data = {}
	save_progress(save_file, data)
	save_settings(save_file, data)
	save_file.store_line(JSON.stringify(data))
	
func save_progress(save_file, data):
	var unlock_tracker = get_tree().get_nodes_in_group("UnlockTracker")[0]
	data["progress"] = unlock_tracker.levels_completed
	
func save_settings(save_file, data):
	data["sound_settings"] = {
		"master": int(db_to_linear(AudioServer.get_bus_volume_db(0)) * 100),
		"talking": int(db_to_linear(AudioServer.get_bus_volume_db(1)) * 100)
		}
	
func load_game():
	if not FileAccess.file_exists(SAVE_FILE_PATH):
		return
	var data = JSON.parse_string(FileAccess.open(SAVE_FILE_PATH, FileAccess.READ).get_line())
	load_progress(data)
	load_settings(data)
	
func load_progress(data):
	var unlock_tracker = get_tree().get_nodes_in_group("UnlockTracker")[0]
	for key in data["progress"].keys():
		unlock_tracker.levels_completed[key] = data["progress"][key]
	
func load_settings(data):
	if data.has("sound_settings"):
		var sound_settings = data["sound_settings"]
		if sound_settings.has("master"):
			SoundManager.set_master_volume(sound_settings["master"])
		if sound_settings.has("talking"):
			SoundManager.set_talk_volume(sound_settings["talking"])
