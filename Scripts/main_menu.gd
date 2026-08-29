extends Node2D

const GRADE_LEVEL_LETTERS = ["k", "e", "m", "h"]
const RULES_LEVELS = ["k0", "m0"]
const ONE_STAR = preload("res://Images/1stars.png")
const TWO_STAR = preload("res://Images/2stars.png")
const THREE_STAR = preload("res://Images/3stars.png")

@onready var grade_levels := $"CanvasLayer/ExamSelectUI/FlowContainer/Grade Levels".get_children()
@onready var volume_number_text := $"CanvasLayer/SettingsUI/VFlowContainer/HFlowContainer/Volume Number"
@onready var talking_volume_number_text := $"CanvasLayer/SettingsUI/VFlowContainer/HFlowContainer2/Volume Number"
@onready var music_volume_number_text := $"CanvasLayer/SettingsUI/VFlowContainer/HFlowContainer3/Volume Number"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	SoundManager.start_music()
				
func check_unlocks():
	for grade in range(GRADE_LEVEL_LETTERS.size()):
		var grade_letter = GRADE_LEVEL_LETTERS[grade]
		var grade_level_buttons := grade_levels[grade].get_node("Level Buttons").get_children()
		for level in range(grade_level_buttons.size()):
			var button_star_container = grade_level_buttons[level]
			var button := button_star_container.get_child(0)
			if (grade == 0 and level == 0) or (get_previous_level_score(grade_letter, level) > 0):
				button.disabled = false
				button.pressed.connect(_on_button_pressed.bind(grade_letter+str(level)))
				var stars := button_star_container.get_child(1)
				match(UnlockTracker.levels_completed[grade_letter+str(level)]):
					1:
						stars.texture = ONE_STAR
					2:
						stars.texture = TWO_STAR
					3:
						stars.texture = THREE_STAR
			else:
				button.disabled = true
				
func check_volume_settings():
	var volume = int(db_to_linear(AudioServer.get_bus_volume_db(0)) * 100)
	set_volume_text(volume)
	$"CanvasLayer/SettingsUI/VFlowContainer/HFlowContainer/Volume Slider".value = volume
	
	var talk_volume = int(db_to_linear(AudioServer.get_bus_volume_db(1)) * 100)
	set_talking_volume_text(volume)
	$"CanvasLayer/SettingsUI/VFlowContainer/HFlowContainer2/Volume Slider".value = talk_volume
	
	var music_volume = int(db_to_linear(AudioServer.get_bus_volume_db(2)) * 100)
	set_music_volume_text(volume)
	$"CanvasLayer/SettingsUI/VFlowContainer/HFlowContainer3/Volume Slider".value = music_volume

func get_previous_level_score(grade, level):
	if level == 0:
		#TODO this wont work if a grade level contains more than 3 levels
		return UnlockTracker.levels_completed[previous_grade_letter(grade)+str(2)]
	else:
		return UnlockTracker.levels_completed[str(grade)+str(level-1)]

func previous_grade_letter(letter):
	return GRADE_LEVEL_LETTERS[GRADE_LEVEL_LETTERS.find(letter)-1]

func _on_button_pressed(level_key) -> void:
	if level_key in RULES_LEVELS:
		get_tree().change_scene_to_file("res://Scenes/Levels/rules_"+str(level_key)+".tscn")
	else:
		get_tree().change_scene_to_file("res://Scenes/Levels/level_"+str(level_key)+".tscn")

func hide_title_elements():
	$CanvasLayer/TitleUI.hide()
	$Title.hide()
	
func show_title_elements():
	$CanvasLayer/TitleUI.show()
	$Title.show()

func _on_play_button_pressed() -> void:
	hide_title_elements()
	prepare_and_show_exam_select()

func _on_settings_button_pressed() -> void:
	hide_title_elements()
	prepare_and_show_settings()
	
func prepare_and_show_settings():
	check_volume_settings()
	$CanvasLayer/SettingsUI.show()
	
func prepare_and_show_exam_select():
	check_unlocks()
	$CanvasLayer/ExamSelectUI.show()

func _on_quit_button_pressed() -> void:
	GameQuitter.request_quit()

func _on_volume_slider_value_changed(value: float) -> void:
	SoundManager.set_master_volume(value)
	set_volume_text(value)
	
func set_volume_text(value):
	volume_number_text.text = str(int(value))
	
func set_talking_volume_text(value):
	talking_volume_number_text.text = str(int(value))
	
func set_music_volume_text(value):
	music_volume_number_text.text = str(int(value))

func _on_settings_back_button_pressed() -> void:
	$CanvasLayer/SettingsUI.hide()
	show_title_elements()

func _on_exam_select_back_button_pressed() -> void:
	$CanvasLayer/ExamSelectUI.hide()
	show_title_elements()

func _on_volume_test_pressed() -> void:
	SoundManager.play_all_sounds_sequential()

func _on_talking_volume_slider_value_changed(value: float) -> void:
	SoundManager.set_talk_volume(value)
	set_talking_volume_text(value)

func _on_talking_volume_test_pressed() -> void:
	SoundManager.play_all_talk_sounds()

func _on__music_volume_slider_value_changed(value: float) -> void:
	SoundManager.set_music_volume(value)
	set_music_volume_text(value)
