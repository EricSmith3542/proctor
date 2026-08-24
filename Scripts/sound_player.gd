class_name SoundPlayer
extends Node2D

signal request_sound(sound)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var sound_manager = find_sound_manager()
	if sound_manager:
		connect_sound_request_signal(sound_manager)

func find_sound_manager() -> Node2D:
	var nodes = get_tree().get_nodes_in_group("SoundManager")
	if nodes.size() > 0:
		return nodes[0]
	print("NO SOUND MANAGER FOUND")
	return null

func connect_sound_request_signal(sound_manager):
	request_sound.connect(sound_manager._on_request_sound)
