extends Node2D

@onready var level_buttons := $LevelButtons.get_children()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for i in range(level_buttons.size()):
		var button := level_buttons[i]
		if i == 0 or UnlockTracker.unlocks[i+1]:
			button.disabled = false
			button.pressed.connect(_on_button_pressed.bind(i+1))


func _on_button_pressed(number) -> void:
	get_tree().change_scene_to_file("res://Scenes/Levels/level"+str(number)+".tscn")
