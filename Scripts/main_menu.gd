extends Node2D

const GRADE_LEVEL_LETTERS = ["k", "e"]

@onready var grade_levels := $"CanvasLayer/ExamSelectUI/FlowContainer/Grade Levels".get_children()
@onready var volume_number_text := $"CanvasLayer/SettingsUI/VFlowContainer/HFlowContainer/Volume Number"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass
				
func check_unlocks():
	for grade in range(GRADE_LEVEL_LETTERS.size()):
		var grade_letter = GRADE_LEVEL_LETTERS[grade]
		var grade_level_buttons := grade_levels[grade].get_node("Level Buttons").get_children()
		for level in range(grade_level_buttons.size()):
			var button := grade_level_buttons[level]
			if (grade == 0 and level == 0) or is_previous_level_completed(grade_letter, level):
				button.disabled = false
				button.pressed.connect(_on_button_pressed.bind(grade_letter+str(level)))
				
func check_volume_settings():
	var volume = int(db_to_linear(AudioServer.get_bus_volume_db(0)) * 100)
	set_volume_text(volume)
	$"CanvasLayer/SettingsUI/VFlowContainer/HFlowContainer/Volume Slider".value = volume

func is_previous_level_completed(grade, level):
	if level == 0:
		#TODO this wont work if a grade level contains more than 3 levels
		return UnlockTracker.levels_completed[previous_grade_letter(grade)+str(2)]
	else:
		return UnlockTracker.levels_completed[str(grade)+str(level-1)]

func previous_grade_letter(letter):
	return GRADE_LEVEL_LETTERS[GRADE_LEVEL_LETTERS.find(letter)-1]

func _on_button_pressed(level_key) -> void:
	get_tree().change_scene_to_file("res://Scenes/Levels/level_"+str(level_key)+".tscn")

func _on_play_button_pressed() -> void:
	$CanvasLayer/TitleUI.hide()
	prepare_and_show_exam_select()

func _on_settings_button_pressed() -> void:
	$CanvasLayer/TitleUI.hide()
	prepare_and_show_settings()
	
func prepare_and_show_settings():
	check_volume_settings()
	$CanvasLayer/SettingsUI.show()
	
func prepare_and_show_exam_select():
	check_unlocks()
	$CanvasLayer/ExamSelectUI.show()

func _on_quit_button_pressed() -> void:
	get_tree().quit()

func _on_volume_slider_value_changed(value: float) -> void:
	SoundManager.set_master_volume(value)
	set_volume_text(value)
	
func set_volume_text(value):
	volume_number_text.text = str(int(value))

func _on_settings_back_button_pressed() -> void:
	$CanvasLayer/SettingsUI.hide()
	$CanvasLayer/TitleUI.show()

func _on_exam_select_back_button_pressed() -> void:
	$CanvasLayer/ExamSelectUI.hide()
	$CanvasLayer/TitleUI.show()
