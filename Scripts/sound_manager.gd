extends Node2D

#TODO Research a cleaner way to do this for full folders
const TEST = preload("res://Sounds/Test.wav")
const TEST_L = preload("res://Sounds/Test_longer.wav")
const AWW = preload("res://Sounds/Aww.wav")
const FAIL = preload("res://Sounds/FailSound.wav")
const LAUGH = preload("res://Sounds/Heheh.wav")
const HEY = preload("res://Sounds/Hey.wav")
const PENCIL = preload("res://Sounds/Pencil-1.wav")
const SUCCESS = preload("res://Sounds/SuccessJingle.wav")
const COUGH = preload("res://Sounds/CoughCough.wav")
const MEE = preload("res://Sounds/Mee.wav")
const MEEP = preload("res://Sounds/Meep.wav")
const MEEP_SMOL = preload("res://Sounds/Smol Meep.wav")
const MEEP2 = preload("res://Sounds/Meep 2.wav")
const MEEP_MERP = preload("res://Sounds/Meep Merp.wav")

const POSSIBLE_TALK_SOUNDS := [MEE, MEEP, MEEP2, MEEP_SMOL, MEEP_MERP]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_to_group("SoundManager")

func _on_request_sound(sound, pos, duration = -1, random_start = false):
	var player = create_stream_player(pos)
	player.stream = sound
	
	if duration == -1:
		player.finished.connect(_on_player_finished.bind(player))
	else:
		var temp_timer = get_tree().create_timer(duration)
		temp_timer.timeout.connect(_on_player_finished(player))
		
	add_child(player)
	
	if random_start:
		player.play(get_random_position_fitting_duration(sound, duration))
	else:
		player.play()
		
func get_random_position_fitting_duration(sound, duration):
	if duration == -1:
		return randf_range(0, sound.get_length())
	return randf_range(0, sound.get_length() - duration)
	
func _on_player_finished(player):
	remove_child(player)
	player.queue_free()

func create_stream_player(pos) -> AudioStreamPlayer2D:
	var player = AudioStreamPlayer2D.new()
	player.position = pos
	return player

func connect_player_delete_to_finished(player, sound):
	player.finished.connect(_on_player_finished.bind(player))
	
func set_master_volume(volume):
	AudioServer.set_bus_volume_db(0, linear_to_db(volume/100))
	
func play_all_sounds_sequential():
	var all_sounds = [AWW, HEY, LAUGH, PENCIL, SUCCESS, FAIL]
	var player = create_stream_player(get_viewport_rect().size / 2)
	add_child(player)
	for sound in all_sounds:
		player.stream = sound
		player.play()
		await player.finished
	remove_child(player)
	player.queue_free()
