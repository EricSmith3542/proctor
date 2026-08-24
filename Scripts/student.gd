class_name Student
extends Node2D

@onready var left_pupil = $"FullHead/Head/Full Left Eye/LeftPupil"
@onready var right_pupil = $"FullHead/Head/Full Right Eye/RightPupil"
@onready var left_look_down_pos = left_pupil.position
@onready var right_look_down_pos = right_pupil.position
@onready var look_left_pos = $FullHead/Head/LeftLookLocation.position
@onready var look_right_pos = $FullHead/Head/RightLookLocation.position
@onready var look_forward_pos = $FullHead/Head/ForwardLookLocation.position

signal accused_of_cheating()
signal request_sound(sound_name)

var is_present = true

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func _input(event):
	if event.is_action_pressed("ui_left"):
		look_left()
	if event.is_action_pressed("ui_right"):
		look_right()
	if event.is_action_pressed("ui_down"):
		look_down()
	if event.is_action_pressed("ui_up"):
		look_forward()
		
func perform_action(action_number, new_action_request_time):
	match(action_number):
		0:
			look_down()
		1:
			look_forward()
		2:
			look_left()
		3:
			look_right()
	$Timer.start(new_action_request_time)
	request_sound.emit("test")
		
		
func look_left():
	left_pupil.position = left_look_down_pos + look_left_pos
	right_pupil.position = right_look_down_pos + look_left_pos
	
func look_right():
	left_pupil.position = left_look_down_pos + look_right_pos
	right_pupil.position = right_look_down_pos + look_right_pos
	
func look_forward():
	left_pupil.position = left_look_down_pos + look_forward_pos
	right_pupil.position = right_look_down_pos + look_forward_pos

func look_down():
	left_pupil.position = left_look_down_pos
	right_pupil.position = right_look_down_pos
	
func mark_absent():
	is_present = false
	$FullHead.hide()

func _on_area_2d_mouse_entered() -> void:
	look_forward()
	
func _on_area_2d_mouse_exited() -> void:
	look_down()

func _on_area_2d_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == 1:
		accused_of_cheating.emit()
