extends Node2D

const TEST = preload("res://Sounds/Test.wav")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_to_group("SoundManager")


func _on_request_sound(sound):
	var new_player = create_stream_player()
	set_and_connect_player(new_player, sound)
	new_player.play()
	print("New Player started. Total Players: ", get_child_count())
	
func _on_player_finished(player):
	remove_child(player)
	player.queue_free()
	print("Player finished and deleted. Total Players: ", get_child_count())

func create_stream_player() -> AudioStreamPlayer2D:
	var player = AudioStreamPlayer2D.new()
	#Change default audio player settings here
	return player

func set_and_connect_player(player, sound):
	player.stream = sound
	player.finished.connect(_on_player_finished.bind(player))
	add_child(player)
