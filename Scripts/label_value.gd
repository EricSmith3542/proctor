extends Control

@export var label_text := "Value"

func _ready() -> void:
	$Label.text = label_text
		
func set_value(value):
	$Value.text = str(value)
