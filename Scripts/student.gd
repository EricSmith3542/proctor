class_name Student
extends SoundPlayer

const MIN_TALK_STATE_TIME := .05
const MAX_TALK_STATE_TIME := .3

@onready var left_pupil = $"FullHead/Head/Full Left Eye/LeftPupil"
@onready var right_pupil = $"FullHead/Head/Full Right Eye/RightPupil"
@onready var left_look_down_pos = left_pupil.position
@onready var right_look_down_pos = right_pupil.position
@onready var look_left_pos = $FullHead/Head/LeftLookLocation.position
@onready var look_right_pos = $FullHead/Head/RightLookLocation.position
@onready var look_forward_pos = $FullHead/Head/ForwardLookLocation.position

@onready var mouth_sprite = $FullHead/Head/Mouth
@onready var talk_timer = $TalkTimer
@onready var mouth_change_timer = $MouthChangeTimer

enum Actions {LOOK_DOWN, LOOK_FORWARD, LOOK_LEFT, LOOK_RIGHT}

signal accused_of_cheating()

var is_present = true
var is_mouth_open = false
var index = -1

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_up") and is_present:
		talk(3)
		
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
	
func stop_performing_actions():
	$Timer.stop()
		
		
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
	
func talk(duration_seconds):
	talk_timer.start(duration_seconds)
	open_mouth()
	start_mouth_change_timer()
	
func start_mouth_change_timer():
	mouth_change_timer.start(randf_range(MIN_TALK_STATE_TIME, MAX_TALK_STATE_TIME))
		
func _on_mouth_change_timer_timeout() -> void:
	close_mouth() if is_mouth_open else open_mouth()
	mouth_change_timer.start(randf_range(MIN_TALK_STATE_TIME, MAX_TALK_STATE_TIME))

func _on_talk_timer_timeout() -> void:
	mouth_change_timer.stop()
	close_mouth()
	
func open_mouth():
	is_mouth_open = true
	SpriteManager.change_sprite(mouth_sprite, SpriteManager.MOUTH_OPEN)
	
func close_mouth():
	is_mouth_open = false
	SpriteManager.change_sprite(mouth_sprite, SpriteManager.MOUTH_CLOSED)
	
func mark_absent():
	is_present = false
	$FullHead.hide()
	$FullDesk/Test.hide()
	
func get_head_center():
	return $FullHead/Head.global_position

func _on_area_2d_mouse_entered() -> void:
	$FullHead/Head.position -= Vector2(0,4)
	
func _on_area_2d_mouse_exited() -> void:
	$FullHead/Head.position += Vector2(0,4)

func _on_area_2d_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == 1:
		accused_of_cheating.emit()
