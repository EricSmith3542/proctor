class_name Level
extends Node2D

@onready var cheat_count_text = $CheatsCountText
@onready var false_accusation_count_text = $FalseAccusationCountText
@onready var fail_text = $FailureText

func _on_level_failed():
	fail_text.visible = true
	await get_tree().create_timer(2.0).timeout
	get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")

func _on_successful_cheat_update(cheat_count):
	cheat_count_text.text = str(cheat_count)

func _on_failed_accusation_update(accusation_count):
	false_accusation_count_text.text = str(accusation_count)

func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")
