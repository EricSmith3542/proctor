class_name Student
extends SoundPlayer

const MIN_TALK_STATE_TIME := .05
const MAX_TALK_STATE_TIME := .3
const BOB_DISTANCE := 10

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
	pick_parts()
	
func pick_parts():
	pass

func perform_action_after_wait(action_number, new_action_request_time, duration, wait):
	$ActionWait.timeout.connect(perform_action.bind(action_number, new_action_request_time, duration))
	$ActionWait.start(wait)

func perform_action(action_number, new_action_request_time, duration):
	match(action_number):
		Classroom.Actions.LOOK_DOWN:
			look_down()
		Classroom.Actions.LOOK_FORWARD:
			look_forward()
		Classroom.Actions.LOOK_LEFT:
			look_left()
		Classroom.Actions.LOOK_RIGHT:
			look_right()
		Classroom.Actions.TALK:
			talk(duration)
		Classroom.Actions.COUGH:
			cough()
	
	if new_action_request_time != -1:
		$Timer.start(new_action_request_time)
	
func stop_performing_actions():
	stop_talking()
	$Timer.stop()
	$ActionWait.stop()
		
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
	
func bob():
	var head = $FullHead/Head
	var start_position = head.position
	var tween = create_tween()
	tween.tween_property(head, "position", start_position + Vector2(0, BOB_DISTANCE), .05)
	tween.tween_property(head, "position", start_position + Vector2(0, -BOB_DISTANCE/2), .03)
	tween.tween_property(head, "position", start_position + Vector2(0, BOB_DISTANCE/4), .02)
	tween.tween_property(head, "position", start_position, .01)
	
func talk(duration_seconds):
	talk_timer.start(duration_seconds)
	open_mouth()
	play_random_talk_sound()
	start_mouth_change_timer()

func play_random_talk_sound():
	play_sound(SoundManager.POSSIBLE_TALK_SOUNDS.pick_random(), get_head_center(), 1)

func stop_talking():
	talk_timer.stop()
	mouth_change_timer.stop()
	close_mouth()
	
func start_mouth_change_timer():
	mouth_change_timer.start(randf_range(MIN_TALK_STATE_TIME, MAX_TALK_STATE_TIME))
		
func _on_mouth_change_timer_timeout() -> void:
	if is_mouth_open:
		close_mouth() 
	else:
		open_mouth()
		play_random_talk_sound()
	mouth_change_timer.start(randf_range(MIN_TALK_STATE_TIME, MAX_TALK_STATE_TIME))

func _on_talk_timer_timeout() -> void:
	mouth_change_timer.stop()
	close_mouth()
	
func cough():
	play_sound(SoundManager.COUGH, get_head_center())
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
		
func show_cheater_text():
	$CheatIndicator.show()

func hide_cheater_text():
	$CheatIndicator.hide()
