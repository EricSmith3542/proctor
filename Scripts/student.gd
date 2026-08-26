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
@onready var cough_timer = $CoughTimer

signal accused_of_cheating()

var is_present = true
var is_mouth_open = false
var index = -1

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super()
		
func perform_action(action_number, new_action_request_time, duration):
	match(action_number):
		Level.Actions.LOOK_DOWN:
			look_down()
		Level.Actions.LOOK_FORWARD:
			look_forward()
		Level.Actions.LOOK_LEFT:
			look_left()
		Level.Actions.LOOK_RIGHT:
			look_right()
		Level.Actions.TALK:
			talk(duration)
		Level.Actions.COUGH:
			cough()
	
	if new_action_request_time != -1:
		$Timer.start(new_action_request_time)
	
func stop_performing_actions():
	stop_talking()
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
	# TODO: play talking sounds for duration
	play_sound(SoundManager.TEST_L, get_head_center())
	talk_timer.start(duration_seconds)
	open_mouth()
	start_mouth_change_timer()

func stop_talking():
	# TODO: kill talking sounds
	talk_timer.stop()
	close_mouth()
	
func start_mouth_change_timer():
	mouth_change_timer.start(randf_range(MIN_TALK_STATE_TIME, MAX_TALK_STATE_TIME))
		
func _on_mouth_change_timer_timeout() -> void:
	close_mouth() if is_mouth_open else open_mouth()
	mouth_change_timer.start(randf_range(MIN_TALK_STATE_TIME, MAX_TALK_STATE_TIME))

func _on_talk_timer_timeout() -> void:
	mouth_change_timer.stop()
	close_mouth()
	
func cough():
	# TODO: PLAY COUGH SOUND
	play_sound(SoundManager.TEST, get_head_center())
	open_mouth()
	cough_timer.start()
	await cough_timer.timeout
	close_mouth()
	await cough_timer.timeout
	open_mouth()
	await cough_timer.timeout
	close_mouth()
	cough_timer.stop()
	
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
