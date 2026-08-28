class_name Level
extends Node2D

@onready var exam_ui_container := $CanvasLayer/ExamUI
@onready var cheat_count_text := $CanvasLayer/ExamUI/CheatsCountText
@onready var false_accusation_count_text := $CanvasLayer/ExamUI/FalseAccusationCountText
@onready var time_left_text := $CanvasLayer/ExamUI/TimeLeftText
@onready var exam_end_ui_panel := $CanvasLayer/ExamEndUIPanel
@onready var countdown_text := $CanvasLayer/MarginContainer3/CountdownText
@onready var start_button := $CanvasLayer/MarginContainer2/StartButton

@onready var classroom := $Classroom
@onready var second_timer := $ExamSecondTimer

@export var grade := "k"
@export var level_number := 1
@export var exam_time_seconds := 60
var remaining_exam_time := exam_time_seconds

var completing_level := false
var cheats_stopped := 0
var false_accusations := 0
var cheats_succeeded := 0

signal level_complete(grade, level)

func _ready() -> void:
	find_and_connect_unlock_tracker()
	connect_exam_end_signals()
	classroom.prepare_classroom(exam_time_seconds)

func connect_exam_end_signals():
	exam_end_ui_panel.connect_continue_pressed_signal(_on_button_pressed)

func find_and_connect_unlock_tracker():
	var nodes = get_tree().get_nodes_in_group("UnlockTracker")
	if nodes.size() > 0:
		var unlock_tracker = nodes[0]
		level_complete.connect(unlock_tracker._on_level_complete)
	else:
		print("NO UNLOCK TRACKER FOUND")

func _on_level_failed():
	second_timer.stop()
	display_fail_screen()
	
func display_fail_screen():
	exam_end_ui_panel.show()
	exam_end_ui_panel.set_win_label(false)
	exam_end_ui_panel.set_all_label_values(cheats_stopped, false_accusations, cheats_succeeded)
	
func display_win_screen():
	exam_end_ui_panel.show()
	exam_end_ui_panel.set_win_label(true)
	exam_end_ui_panel.set_all_label_values(cheats_stopped, false_accusations, cheats_succeeded)

func _on_successful_cheat_update(cheat_count):
	cheat_count_text.text = str(cheat_count)
	cheats_succeeded = cheat_count

func _on_failed_accusation_update(accusation_count):
	false_accusation_count_text.text = str(accusation_count)
	false_accusations = accusation_count
	
func _on_cheat_stopped():
	cheats_stopped += 1

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
	elif not completing_level:
		completing_level = true
		level_complete.emit(grade, level_number)
		classroom.enter_win_state()
		display_win_screen()
