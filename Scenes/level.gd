class_name Level
extends Node2D

@onready var exam_ui_container := $ExamUI
@onready var cheat_count_text := $ExamUI/CheatsCountText
@onready var false_accusation_count_text := $ExamUI/FalseAccusationCountText
@onready var time_left_text := $ExamUI/TimeLeftText
@onready var fail_text := $FailureText
@onready var win_text := $WinText
@onready var countdown_text := $CountdownText
@onready var start_button := $StartButton

@onready var classroom := $Classroom
@onready var second_timer := $ExamSecondTimer

@export var exam_time_seconds := 60
var remaining_exam_time := exam_time_seconds

func _on_level_failed():
	fail_text.visible = true
	await get_tree().create_timer(2).timeout
	get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")

func _on_successful_cheat_update(cheat_count):
	cheat_count_text.text = str(cheat_count)

func _on_failed_accusation_update(accusation_count):
	false_accusation_count_text.text = str(accusation_count)

func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")

func _on_start_button_pressed():
	await countdown_to_exam_start()
	remaining_exam_time = exam_time_seconds
	set_timer_text(remaining_exam_time)
	start_button.visible = false
	exam_ui_container.visible = true
	second_timer.start()
	classroom.start_exam()

func countdown_to_exam_start():
	countdown_text.visible = true
	var countdown_array = range(3)
	countdown_array.reverse()
	for i in countdown_array:
		countdown_text.text = str(i+1)
		await get_tree().create_timer(1).timeout
	countdown_text.text = "Begin"
	await get_tree().create_timer(1).timeout
	countdown_text.text = ""
	countdown_text.visible = false
	
func set_timer_text(seconds):
	time_left_text.text = str(seconds)

func _on_exam_second_timer_timeout() -> void:
	remaining_exam_time -= 1
	if remaining_exam_time >= 0:
		set_timer_text(remaining_exam_time)
	else:
		win_text.visible = true
		await get_tree().create_timer(2).timeout
		get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")
