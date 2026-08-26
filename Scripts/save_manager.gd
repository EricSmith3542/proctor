extends Node2D


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
	var save_file = FileAccess.open("user://savegame.save", FileAccess.WRITE)
	var data = {}
	save_progress(save_file, data)
	save_settings(save_file, data)
	save_file.store_line(JSON.stringify(data))
	
func save_progress(save_file, data):
	var unlock_tracker = get_tree().get_nodes_in_group("UnlockTracker")[0]
	data["progress"] = unlock_tracker.levels_completed
	
func save_settings(save_file, data):
	data["sound_settings"] = {"master": int(db_to_linear(AudioServer.get_bus_volume_db(0)) * 100)}
	
func load_game():
	if not FileAccess.file_exists("user://savegame.save"):
		return
		
	var data = JSON.parse_string(FileAccess.open("user://savegame.save", FileAccess.READ).get_line())
	load_progress(data)
	load_settings(data)
	
func load_progress(data):
	var unlock_tracker = get_tree().get_nodes_in_group("UnlockTracker")[0]
	unlock_tracker.levels_completed = data["progress"]
	
func load_settings(data):
	SoundManager.set_master_volume(data["sound_settings"]["master"])
