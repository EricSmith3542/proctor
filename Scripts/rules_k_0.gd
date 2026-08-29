extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Student0.look_left()
	$Student1.look_left()
	$Student1.show_cheater_text()
	$Student2.look_forward()
	
	$Student3.look_right()
	$Student4.mark_absent()
	$Student5.look_down()
	
	$Student6.look_down()
	$Student7.look_forward()
	$Student8.look_right()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")


func _on_continue_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Levels/level_k0.tscn")
