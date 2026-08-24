class_name Student
extends SoundPlayer

@onready var left_pupil = $"FullHead/Head/Full Left Eye/LeftPupil"
@onready var right_pupil = $"FullHead/Head/Full Right Eye/RightPupil"
@onready var left_look_down_pos = left_pupil.position
@onready var right_look_down_pos = right_pupil.position
@onready var look_left_pos = $FullHead/Head/LeftLookLocation.position
@onready var look_right_pos = $FullHead/Head/RightLookLocation.position
@onready var look_forward_pos = $FullHead/Head/ForwardLookLocation.position

enum Actions {LOOK_DOWN, LOOK_FORWARD, LOOK_LEFT, LOOK_RIGHT}

signal accused_of_cheating()

var is_present = true
var index = -1

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super()

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
		Actions.LOOK_DOWN:
			look_down()
		Actions.LOOK_FORWARD:
			look_forward()
		Actions.LOOK_LEFT:
			look_left()
		Actions.LOOK_RIGHT:
			look_right()
	$Timer.start(new_action_request_time)
	request_sound.emit(SoundManager.TEST)
		
		
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
	print("hovering")
	
func _on_area_2d_mouse_exited() -> void:
	print("hover exit")

func _on_area_2d_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == 1:
		accused_of_cheating.emit()
