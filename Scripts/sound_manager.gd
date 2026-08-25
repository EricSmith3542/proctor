extends Node2D

const TEST = preload("res://Sounds/Test.wav")
const TEST_L = preload("res://Sounds/Test_longer.wav")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_to_group("SoundManager")

func _on_request_sound(sound, pos = get_viewport_rect().size / 2):
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
