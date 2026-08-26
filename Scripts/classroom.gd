class_name Classroom
extends SoundPlayer

const STUDENT = preload("res://Scenes/student.tscn")
const STUDENT_WIDTH = 128
const STUDENT_HEIGHT = 200
const SAFE_ACTIONS = [0, 1]

signal level_failed
signal cheat_stopped
signal successful_cheat_update(cheat_count)
signal failed_accusation_update(accusation_count)

@onready var student_container = $StudentContainer

var present_indices = []
var active_cheaters = {}
var successful_cheats = 0
var false_accusations = 0
var exam_in_progress = false

@export var number_of_students = 8

#Softcap of 5x8
@export_range(1, 100, 1) var rows_of_desks : int = 3
@export_range(1, 100, 1) var cols_of_desks : int = 3

@export var max_random_wait_seconds = 60
@export var fixed_cheat_time_seconds = 5

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super()
	make_students()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
		
		
func make_students():
	var area_bounds = $StudentArea/StudentAreaShape.shape.size
	
	#	Determine left right padding for student placement
	#	Desk columns * 2 - 1 to account for vertical walk ways
	var total_horizontal_space = (cols_of_desks*2 - 1) * STUDENT_WIDTH
	var padding_x = (area_bounds.x - total_horizontal_space)/2
	
	var total_vertical_space = rows_of_desks * STUDENT_HEIGHT
	var padding_y = (area_bounds.y - total_vertical_space)/2
	
	#	Place student scenes
	var current_x_pos = padding_x
	var current_y_pos = padding_y
	for row in range(rows_of_desks):
		for col in range(cols_of_desks):
			var student = STUDENT.instantiate()
			student.position = position + Vector2(current_x_pos, current_y_pos)
			student_container.add_child(student)
			current_x_pos += STUDENT_WIDTH*2
		current_y_pos += STUDENT_HEIGHT
		current_x_pos = padding_x
	
	#	Remove students to match number_of_students
	var remaining_indices = range(rows_of_desks * cols_of_desks)
	var num_students = min(number_of_students, rows_of_desks * cols_of_desks)
	for i in num_students:
		var random_pick = remaining_indices.pick_random()
		remaining_indices.remove_at(remaining_indices.find(random_pick))
		present_indices.append(random_pick)
	
	for i in range(student_container.get_children().size()):
		var student = student_container.get_child(i)
		if i not in present_indices:
			student.mark_absent()
		else:
			prepare_student(student, i)
			
func prepare_student(student, index):
	student.index = index
	student.accused_of_cheating.connect(_on_student_accused.bind(index))
	student.get_node("Timer").timeout.connect(_on_student_requests_action.bind(student))
	student.look_forward()
	#start_random_action_random_wait(student)

func start_exam():
	# TODO: post mvp this is where you would trigger picking up pencils
	exam_in_progress = true
	#Start random actions
	for student in student_container.get_children():
		if student.is_present:
			student.stop_performing_actions()
			start_action_random_wait(student, 0)

func start_action_random_wait(student, action, fixed_cheat_time = true):
	if is_student_cheating(student, action):
		active_cheaters[student.index] = action
		if fixed_cheat_time:
			student.perform_action(action, fixed_cheat_time_seconds)
			return
	student.perform_action(action, get_random_wait_seconds())

func start_random_action_random_wait(student, fixed_cheat_time = true):
	var random_action = range(Student.Actions.size()).pick_random()
	start_action_random_wait(student, random_action, exam_in_progress and fixed_cheat_time)
	
func increment_cheat_count():
	successful_cheats += 1
	successful_cheat_update.emit(successful_cheats)
	check_for_fail()
	
func increment_false_accusations():
	false_accusations += 1
	failed_accusation_update.emit(false_accusations)
	check_for_fail()

func handle_if_cheating(student):
	if active_cheaters.has(student.index):
		print("Student ", student.index, " cheated with action ", active_cheaters[student.index])
		play_sound(SoundManager.LAUGH, student.get_head_center())
		increment_cheat_count()
		active_cheaters.erase(student.index)
		return true
	return false
		
func get_student_by_index(index):
	return student_container.get_child(index)
	
func get_random_wait_seconds() -> float:
	var rand_seconds = randf_range(1,max_random_wait_seconds)
	return randf_range(1,max_random_wait_seconds)
	
func is_student_cheating(student, action):
	if not exam_in_progress:
		return false
		
	match(action):
		Student.Actions.LOOK_DOWN, Student.Actions.LOOK_FORWARD:
			return false
		Student.Actions.LOOK_LEFT:
			if student.index % cols_of_desks == 0:
				return false
			if not get_student_by_index(student.index - 1).is_present:
				return false
			print("Student ", student.index, " attempting cheat with look_left")
			return true
		Student.Actions.LOOK_RIGHT:
			if student.index % cols_of_desks == cols_of_desks - 1:
				return false
			if not get_student_by_index(student.index + 1).is_present:
				return false
			print("Student ", student.index, " attempting cheat with look_right")
			return true

func check_for_fail():
	if false_accusations + successful_cheats >= 3:
		enter_fail_state()
		
func enter_fail_state():
	exam_in_progress = false
	stop_all_student_actions()
	play_sound(SoundManager.FAIL)
	level_failed.emit()
	
func enter_win_state():
	exam_in_progress = false
	play_sound(SoundManager.SUCCESS)
	stop_all_student_actions()

func stop_all_student_actions():
	for student in student_container.get_children():
		student.stop_performing_actions()

func _on_student_requests_action(student):
	if handle_if_cheating(student):
		start_action_random_wait(student, Student.Actions.LOOK_DOWN)
	else:
		start_random_action_random_wait(student)

func _on_student_accused(index):
	if not exam_in_progress:
		return
	
	var student = get_student_by_index(index)
	if active_cheaters.has(index):
		cheat_stopped.emit()
		print("Stopped student ", index, " from cheating")
		active_cheaters.erase(index)
		play_sound(SoundManager.AWW, student.get_head_center())
		start_action_random_wait(student, 0)
	else:
		print("Falsely accused student ", index, " of cheating")
		play_sound(SoundManager.HEY, student.get_head_center())
		increment_false_accusations()
