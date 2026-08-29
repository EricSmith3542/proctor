extends SoundPlayer

signal timer_started
signal timer_finished

const BUTTON_DOWN_DISTANCE := 10
const COUNTDOWN_SECONDS := 3

var time_seconds := 15
var ticks_remaining := 0
@onready var button := $Body/Button
@onready var hand := $Body/HandPivot
@onready var body := $Body



func _on_timer_clicked():
	timer_started.emit()
	ticks_remaining = time_seconds
	var hand_tween = create_tween()
	hand_tween.tween_property(hand, "rotation", deg_to_rad(0), COUNTDOWN_SECONDS)
	hand_tween.tween_callback(button_down)
	
func button_down():
	var button_tween = create_tween()
	button_tween.tween_property(button, "position", button.position + Vector2(0, BUTTON_DOWN_DISTANCE), .05)
	tick_down()
	
func tick_down():
	var tick_tween = create_tween()
	tick_tween.tween_property(hand, "rotation", hand.rotation + deg_to_rad(360/time_seconds), .2)
	tick_tween.tween_callback(finish_and_start_new_tick)
	
func finish_and_start_new_tick():
	await get_tree().create_timer(.8).timeout
	ticks_remaining -= 1
	if ticks_remaining > 0:
		tick_down()
	
func ring():
	timer_finished.emit()
	print("ruzz the body and parts")
	
func _on_area_2d_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == 1:
		_on_timer_clicked()
