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

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_to_group("SoundManager")

func _on_request_sound(sound, pos):
	var new_player = create_stream_player(pos)
	set_and_connect_player(new_player, sound)
	new_player.play()
	
func _on_player_finished(player):
	remove_child(player)
	player.queue_free()

func create_stream_player(pos) -> AudioStreamPlayer2D:
	var player = AudioStreamPlayer2D.new()
	player.position = pos
	return player

func set_and_connect_player(player, sound):
	player.stream = sound
	player.finished.connect(_on_player_finished.bind(player))
	add_child(player)
	
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
