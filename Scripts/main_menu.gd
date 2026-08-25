extends Node2D

const GRADE_LEVEL_LETTERS = ["k", "e"]

@onready var grade_levels := $"CanvasLayer/HBoxContainer/FlowContainer/Grade Levels".get_children()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for grade in range(GRADE_LEVEL_LETTERS.size()):
		var grade_level_buttons := grade_levels[grade].get_node("Level Buttons").get_children()
		for level in range(grade_level_buttons.size()):
			var button := grade_level_buttons[level]
			var grade_letter = GRADE_LEVEL_LETTERS[grade]
			if (grade == 0 and level == 0) or is_previous_level_completed(grade_letter, level):
				button.disabled = false
				button.pressed.connect(_on_button_pressed.bind(grade_letter+str(level)))

func is_previous_level_completed(grade, level):
	if level == 0:
		#TODO this wont work if a grade level contains more than 3 levels
		return UnlockTracker.levels_completed[previous_grade_letter(grade)+str(2)]
	else:
		return UnlockTracker.levels_completed[str(grade)+str(level-1)]

func previous_grade_letter(letter):
	return GRADE_LEVEL_LETTERS[GRADE_LEVEL_LETTERS.find(letter)-1]

func _on_button_pressed(level_key) -> void:
	get_tree().change_scene_to_file("res://Scenes/Levels/level"+str(level_key)+".tscn")
