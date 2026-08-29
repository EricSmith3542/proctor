extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$"NonTalking Students/Student1".mark_absent()
	$"NonTalking Students/Student2".mark_absent()
	
	$"NonTalking Students/Student3".mark_absent()
	
	_on_talk_timer_timeout()
	$CoughTimer.start(3)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")


func _on_continue_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Levels/level_m0.tscn")


func _on_talk_timer_timeout() -> void:
	$Student0.talk(5)
	$Student5.talk(5)
	$TalkTimer.start(6)


func _on_cough_timer_timeout() -> void:
	$"NonTalking Students".get_children().pick_random().cough()
	$CoughTimer.start(3)
