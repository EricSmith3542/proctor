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
@onready var wave_timer = $WaveTimer

var present_indices = []
var active_cheaters = {}
var successful_cheats = 0
var false_accusations = 0
var exam_in_progress = false

var number_of_students = 1

var rows_of_desks := 1
var cols_of_desks := 1
var fixed_cheat_time_seconds := 5
var action_frequency := 1
var cheat_frequency := .1
var max_actions_per_wave := 1
var min_actions_per_wave := 1

var action_wave_jitter_seconds = 3
var allowed_actions = []

# This is no longer a difficulty related control and just dicates behavior pre-exam
var max_random_wait_seconds = 15

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super()
	
func prepare_classroom(num_students, rows, cols, cheat_time, a_freq, c_freq, max_action, min_action, jitter, actions):
	number_of_students = num_students
	rows_of_desks = rows
	cols_of_desks = cols
	fixed_cheat_time_seconds = cheat_time
	max_actions_per_wave = min(max_action, num_students)
	min_actions_per_wave = min(min_action, num_students)
	action_wave_jitter_seconds = jitter
	allowed_actions = actions
	make_students()		
		
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
	
	
	# Prepare students in present indicies and empty other desks
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
	start_random_action_random_wait(student)
			
func start_random_action_random_wait(student, fixed_cheat_time = true):
	var random_action = range(Level.Actions.size()).pick_random()
	start_action_random_wait(student, random_action, exam_in_progress and fixed_cheat_time)

func start_action_random_wait(student, action, fixed_cheat_time = true):
	if is_student_cheating(action, student):
		print("SHOULD NEVER GET HERE")
		active_cheaters[student.index] = action
		if fixed_cheat_time:
			student.perform_action(action, fixed_cheat_time_seconds, fixed_cheat_time_seconds)
			return
	student.perform_action(action, get_random_wait_seconds(), get_random_talk_seconds())
	
func start_exam():
	# TODO: post mvp this is where you would trigger picking up pencils
	# All students look down at start of exam
	for student in student_container.get_children():
		if student.is_present:
			student.stop_performing_actions()
			student.look_down()
	exam_in_progress = true
	start_action_waves()
	
func start_action_waves():
	wave_timer.start(get_jittered_wave_timer())
	
func get_jittered_wave_timer():
	return randf_range(max(0, action_frequency - 3), action_frequency + 3)
	
func _on_wave_timer_timeout() -> void:
	start_actions()
	wave_timer.start(get_jittered_wave_timer())
	
func start_actions():
	var all_students = student_container.get_children()
	var all_present_students = all_students.filter(func(student): return student.is_present)
	var all_student_indicies = []
	for student in all_present_students:
		all_student_indicies.append(student.index)
	var students_ready_for_action = all_student_indicies.filter(func(index): return index not in active_cheaters.keys())
	var actions_to_take = min(randi_range(min_actions_per_wave, max_actions_per_wave), students_ready_for_action.size())
	
	print("WAVE STARTING. Taking ", actions_to_take, " actions. Ready students: ", students_ready_for_action)
	for i in range(actions_to_take):
		var student_index = students_ready_for_action.pick_random()
		students_ready_for_action.remove_at(students_ready_for_action.find(student_index))
		var student = all_students[student_index]
		var picked_action
		var should_cheat = randf() <= cheat_frequency
		var wait_before_action = randf_range(0,2)
		if should_cheat:
			var cheat_actions = get_cheating_actions_for_student(student)
			if cheat_actions.size() > 0:
				picked_action = cheat_actions.pick_random()
				active_cheaters[student.index] = picked_action
				student.perform_action_after_wait(picked_action, -1, fixed_cheat_time_seconds, wait_before_action)
				var temp_timer = get_tree().create_timer(fixed_cheat_time_seconds)
				temp_timer.timeout.connect(handle_if_cheating.bind(student))
				print("Picked cheat ", picked_action, " from ", cheat_actions)
		else:
			var safe_actions = get_safe_actions_for_student(student)
			picked_action = safe_actions.pick_random()
			student.perform_action_after_wait(picked_action, -1, get_random_talk_seconds(), wait_before_action)
		print("Student ", student_index, " taking action ", Level.Actions.find_key(picked_action), " in ", wait_before_action,  "seconds. CHEATING = ", should_cheat)
			
func get_cheating_actions_for_student(student):
	return allowed_actions.filter(is_student_cheating.bind(student))
	
func get_safe_actions_for_student(student):
	return allowed_actions.filter(is_student_not_cheating.bind(student))

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
		student.look_down()
		increment_cheat_count()
		active_cheaters.erase(student.index)
		return true
	return false
		
func get_student_by_index(index):
	return student_container.get_child(index)
	
func get_random_wait_seconds() -> float:
	return randf_range(1,max_random_wait_seconds)
	
func get_random_talk_seconds() -> float:
	return randf_range(2,fixed_cheat_time_seconds)
	
func is_student_not_cheating(action, student):
	return !is_student_cheating(action, student)

func is_student_cheating(action, student):
	if not exam_in_progress:
		return false
		
	match(action):
		Level.Actions.LOOK_DOWN, Level.Actions.LOOK_FORWARD, Level.Actions.COUGH:
			return false
		Level.Actions.LOOK_LEFT:
			return has_neighbor_left(student)
		Level.Actions.LOOK_RIGHT:
			return has_neighbor_right(student)
		Level.Actions.TALK:
			return has_any_neighbor(student)
			
func has_neighbor_left(student):
	if student.index % cols_of_desks == 0:
		return false
	return get_student_by_index(student.index - 1).is_present
	
func has_neighbor_right(student):
	if student.index % cols_of_desks == cols_of_desks - 1:
		return false
	return get_student_by_index(student.index + 1).is_present
	
func has_neighbor_up(student):
	if rows_of_desks == 1 or student.index / cols_of_desks == 0:
		return false
	return get_student_by_index(student.index - cols_of_desks).is_present
	
func has_neighbor_down(student):
	if rows_of_desks == 1 or student.index / cols_of_desks == rows_of_desks - 1:
		return false
	return get_student_by_index(student.index + cols_of_desks).is_present
	
func has_any_neighbor(student):
	return has_neighbor_down(student) or has_neighbor_up(student) or has_neighbor_left(student) or has_neighbor_right(student)

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
	active_cheaters = {}
	stop_all_student_actions()
	wave_timer.stop()

func stop_all_student_actions():
	for student in student_container.get_children():
		student.stop_performing_actions()

func _on_student_requests_action(student):
	if handle_if_cheating(student):
		start_action_random_wait(student, Level.Actions.LOOK_DOWN)
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
		student.stop_talking()
		student.look_down()
	else:
		print("Falsely accused student ", index, " of cheating")
		play_sound(SoundManager.HEY, student.get_head_center())
		increment_false_accusations()
