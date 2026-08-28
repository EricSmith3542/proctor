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

@export var number_of_students = 8
@export_range(1, 100, 1) var rows_of_desks : int = 3
@export_range(1, 100, 1) var cols_of_desks : int = 3
@export var fixed_cheat_time_seconds = 5
@export var action_wave_frequency := 1
@export var action_wave_jitter := 3
@export var cheat_frequency := .1
@export_range(1, 100, 1, "or_greater") var max_actions_per_wave := 1
@export_range(1, 100, 1, "or_greater") var min_actions_per_wave := 1

enum Actions {LOOK_DOWN, LOOK_FORWARD, LOOK_LEFT, LOOK_RIGHT, TALK, COUGH}
@export var allowed_actions:Array[Actions] = [Actions.LOOK_DOWN, Actions.LOOK_FORWARD, Actions.LOOK_LEFT, Actions.LOOK_RIGHT]

@export var action_slot_time_seconds := .5
var action_slots = []
@export var action_slots_per_cheat := 1

@export_range(0, 100, 1, "or_greater") var max_paired_action_slot_spread := 0

enum Action_Strategy {RANDOM, RANDOM_CHEAT, DOUBLE_CHEAT, SPREAD_DOUBLE_CHEAT}
@export var strategies:Array[Action_Strategy] = []

@export var min_cheat_separation_slots := 5
@export var min_non_cheat_separation_slots := 5

var present_indices = []
var active_cheaters = {}
var successful_cheats = 0
var false_accusations = 0
var exam_in_progress = false

var action_frequency := 1
var action_wave_jitter_seconds = 3

# This is no longer a difficulty related control and just dicates behavior pre-exam
var max_random_wait_seconds = 15

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super()
	
class ActionPlan:
	var action: Actions = Actions.LOOK_DOWN
	var student_index: int = -1
	var action_slot_duration: int = 1
	var is_cheat: bool = false
	
	func _init(action_, student_index_, duration_, is_cheat_) -> void:
		action = action_
		student_index = student_index_
		action_slot_duration = duration_
		is_cheat = is_cheat_
		
	func _to_string() -> String:
		return "Student " + str(student_index) + " takes " + str(Actions.find_key(action)) + " for " + str(action_slot_duration) + " slots"

func execute_action_plan(plan:ActionPlan):
	var student = get_student_by_index(plan.student_index)
	student.perform_action(plan.action, -1, plan.action_slot_duration * action_slot_time_seconds)
	
func prepare_classroom(exam_time_seconds):
	make_students()
	make_all_action_plans(exam_time_seconds)
		
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
		
func make_all_action_plans(exam_time_seconds):	
	for i in range(exam_time_seconds/action_slot_time_seconds):
		action_slots.append([])
		
	var window_size = 1 + max_paired_action_slot_spread
	var possible_window_positions = range(action_slots.size() - window_size)
	possible_window_positions.shuffle()
		
	for strategy in strategies:
		if not apply_strategy(strategy, window_size, possible_window_positions):
			print("FAILED TO APPLY STRATEGY AND ALL FALLBACKS. PLAN COMPLETE")
			break
		
	print_action_plan()
	
func print_action_plan():
	var msg = ""
	for i in action_slots.size():
		msg += "Slot " + str(i) + ":\n"
		var slot = action_slots[i]
		for plan in slot:
			msg += str(plan) + " | "
		msg += "\n"
	print(msg)
		
func apply_strategy(strategy, window_size, possible_window_positions):
	possible_window_positions.shuffle()
	var student_options = present_indices.duplicate()
	var strategy_applied = false
	print("All present students: ", student_options)
	
	match(strategy):
		Action_Strategy.RANDOM:
			strategy_applied = apply_random_non_cheat(student_options)
		Action_Strategy.RANDOM_CHEAT:
			strategy_applied = apply_random_cheat(student_options)
			if not strategy_applied:
				print("Random cheat failed to be applied. Fallback to single non-cheat")
				return apply_strategy(Action_Strategy.RANDOM, window_size, possible_window_positions)
		Action_Strategy.DOUBLE_CHEAT:
			strategy_applied = apply_double_cheat(window_size, possible_window_positions, student_options)
			if not strategy_applied:
				print("Double cheat failed to be applied. Fallback to single cheat")
				return apply_strategy(Action_Strategy.RANDOM_CHEAT, window_size, possible_window_positions)
		Action_Strategy.SPREAD_DOUBLE_CHEAT:
			strategy_applied = apply_spread_double_cheat(window_size, possible_window_positions, student_options)
			if not strategy_applied:
				print("Spread double cheat failed to be applied. Fallback to normal double cheat")
				return apply_strategy(Action_Strategy.DOUBLE_CHEAT, window_size, possible_window_positions)
	return strategy_applied
		
func apply_random_non_cheat(student_options):
	while student_options.size() > 0:
		var random_student_index = pop_random(student_options)
		print("Picked student ", random_student_index, ". REMAINING: ", student_options)
		var cheat_actions = get_possible_cheating_actions_for_student(random_student_index)
		var random_student_actions = allowed_actions.filter(func(action): return action not in cheat_actions)
		if random_student_actions.size() > 0:
			if try_apply_action(random_student_index, random_student_actions.pick_random()):
				return true
	return false
	
func try_apply_action(student_index, action):
	var ready_slots = get_readied_slots_for_student_in_window(student_index, 0, action_slots.size(), false)
	if ready_slots.size() > 0:
		var slot = ready_slots.pick_random()
		var action_plan = ActionPlan.new(action, student_index, randi_range(1,action_slots_per_cheat), false)
		action_slots[slot].append(action_plan)
		return true
	return false
			
func apply_random_cheat(student_options):
	while student_options.size() > 0:
		var random_student_index = pop_random(student_options)
		print("Picked student ", random_student_index, ". REMAINING: ", student_options)
		var random_student_cheat_actions = get_possible_cheating_actions_for_student(random_student_index)
		if random_student_cheat_actions.size() > 0:
			if try_apply_cheat(random_student_index, random_student_cheat_actions.pick_random()):
				return true
		else:
			print("Student ", random_student_index, " cant cheat")
	return false
	
func try_apply_cheat(cheater_index, cheat_action):
	var ready_slots_for_cheater = get_readied_slots_for_student_in_window(cheater_index, 0, action_slots.size(), true)
	if ready_slots_for_cheater.size() > 0:
		var cheat_slots_for_cheater = ready_slots_for_cheater.filter(func(slot_index): return slot_index + action_slots_per_cheat - 1 < action_slots.size())
		if cheat_slots_for_cheater.size() > 0:
			var slot = cheat_slots_for_cheater.pick_random()
			var action_plan = ActionPlan.new(get_possible_cheating_actions_for_student(cheater_index).pick_random(), cheater_index, action_slots_per_cheat, true)
			action_slots[slot].append(action_plan)
			return true
	return false
			
	
func apply_double_cheat(window_size, possible_window_positions, student_options):
	var all_student_options = student_options.duplicate()
	while student_options.size() > 0:
		var random_student_index = pop_random(student_options)
		print("Picked student ", random_student_index, ". REMAINING: ", student_options)
		var random_student_cheat_actions = get_possible_cheating_actions_for_student(random_student_index)
		if random_student_cheat_actions.size() > 0:
			var other_students = all_student_options.duplicate()
			other_students.erase(random_student_index)
			print("Students that are not student ", random_student_index, " are ", other_students)
			for other_index in other_students:
				var other_cheat_actions = get_possible_cheating_actions_for_student(other_index)
				if other_cheat_actions.size() > 0:
					print("Other student ", other_index, " can cheat: ", other_cheat_actions)
					# Determine action slot window and randomly check all possible window positions, picking first one
					for window_position in possible_window_positions:
						if try_apply_multi_cheat_in_window([random_student_index, other_index], window_position, window_size):
							return true
				else:
					print("Other student ", other_index, " cant cheat")
		else:
			print("Student ", random_student_index, " cant cheat")
	return false

func apply_spread_double_cheat(window_size, possible_window_positions, student_options):
	possible_window_positions.shuffle()
	
	while student_options.size() > 0:
		var random_student_index = pop_random(student_options)
		print("Picked student ", random_student_index, ". REMAINING: ", student_options)
		var random_student_cheat_actions = get_possible_cheating_actions_for_student(random_student_index)
		if random_student_cheat_actions.size() > 0:
			print("Student ", random_student_index, " can cheat: ", random_student_cheat_actions)
			var spread_students = get_spread_present_students_for_student(random_student_index)
			print("Student ", random_student_index, " is not adjacent to ", spread_students)
			for other_index in spread_students:
				var other_cheat_actions = get_possible_cheating_actions_for_student(other_index)
				if other_cheat_actions.size() > 0:
					print("Other student ", other_index, " can cheat: ", other_cheat_actions)
					# Determine action slot window and randomly check all possible window positions, picking first one
					for window_position in possible_window_positions:
						if try_apply_multi_cheat_in_window([random_student_index, other_index], window_position, window_size):
							return true
				else:
					print("Other student ", other_index, " cant cheat")
		else:
			print("Student ", random_student_index, " cant cheat")
	return false

func try_apply_multi_cheat_in_window(cheater_indicies, window_position, window_size):
	if window_position + action_slots_per_cheat >= action_slots.size():
		print("No possible cheats with window position ", window_position, " and cheat duration of ", action_slots_per_cheat, " slots with ", action_slots.size(), " total slots.")
		return false
				
	var plan_slot_map = {}
	for cheater_index in cheater_indicies:
		var ready_slots_for_cheater = get_readied_slots_for_student_in_window(cheater_index, window_position, window_size, true)
		if ready_slots_for_cheater.size() > 0:
			var cheat_slots_for_cheater = ready_slots_for_cheater.filter(func(slot_index): return slot_index + action_slots_per_cheat - 1 < action_slots.size())
			if cheat_slots_for_cheater.size() > 0:
				var slot = cheat_slots_for_cheater.pick_random()
				var action_plan = ActionPlan.new(get_possible_cheating_actions_for_student(cheater_index).pick_random(), cheater_index, action_slots_per_cheat, true)
				var slot_plan_object = {"slot": slot, "plan": action_plan}
				plan_slot_map[cheater_index] = slot_plan_object
				print("Added plan for cheater ", cheater_index, ": ", slot_plan_object)
	
	print("Students with plans: ", plan_slot_map.keys(), " All cheaters: ", cheater_indicies)
	if plan_slot_map.keys().size() == cheater_indicies.size():
		apply_plans(plan_slot_map)
		print("Applied plan: ", plan_slot_map)
		return true
	else:
		#print("Failed to apply multi cheat for ", cheater_indicies, " in window ", get_action_slot_indicies_in_window(window_position, window_size))
		return false
			
func apply_plans(plan_slot_map):
	for student_index in plan_slot_map.keys():
		var student_plan = plan_slot_map[student_index]
		action_slots[student_plan["slot"]].append(student_plan["plan"])
			
# Returns all action slots in the window that are not covered by the duration of previous action plans for the student
func get_readied_slots_for_student_in_window(student_index, window_position, window_size, is_cheating):
	var readied_slot_indicies = get_action_slot_indicies_in_window(window_position, window_size)
	var window_end = window_position + window_size - 1
	for i in action_slots.size() :
		var action_plans = action_slots[i]
		for action_plan in action_plans:
			if action_plan.is_cheat and is_cheating:
				var filtered_indicies = []
				for ready_slot in readied_slot_indicies:
					if ready_slot > i and ready_slot - min_cheat_separation_slots >= i:
						filtered_indicies.append(ready_slot)
					elif ready_slot <= i and ready_slot + min_cheat_separation_slots <= i:
						filtered_indicies.append(ready_slot)
				readied_slot_indicies = filtered_indicies
			elif not action_plan.is_cheat and not is_cheating:
				var filtered_indicies = []
				for ready_slot in readied_slot_indicies:
					if ready_slot > i and ready_slot - min_non_cheat_separation_slots >= i:
						filtered_indicies.append(ready_slot)
					elif ready_slot <= i and ready_slot + min_non_cheat_separation_slots <= i:
						filtered_indicies.append(ready_slot)
				readied_slot_indicies = filtered_indicies
			if action_plan.student_index == student_index:
				var slots_used_by_action = range(i, action_plan.action_slot_duration + i)
				readied_slot_indicies = readied_slot_indicies.filter(func(index): return index not in slots_used_by_action)
			if readied_slot_indicies.size() <= 0:
				return []
	return readied_slot_indicies

func get_action_slot_indicies_in_window(window_position, window_size):
	return range(action_slots.size()).slice(window_position, window_size + window_position) 

func get_possible_cheating_actions_for_student(student_index):
	var cheat_actions = []
	for action in allowed_actions:
		match(action):
			Actions.LOOK_DOWN, Actions.LOOK_FORWARD, Actions.COUGH:
				continue
			Actions.LOOK_LEFT:
				if has_neighbor_left(student_index):
					cheat_actions.append(Actions.LOOK_LEFT)
			Actions.LOOK_RIGHT:
				if has_neighbor_right(student_index):
					cheat_actions.append(Actions.LOOK_RIGHT)
			Actions.TALK:
				if has_any_neighbor(student_index):
					cheat_actions.append(Actions.TALK)
	return cheat_actions
	
func get_spread_present_students_for_student(student_index):
	var spread_indicies = []
	for i in present_indices:
		if i == student_index or is_adjacent_index(i, student_index):
			#print(i, " is adjacent to ", student_index)
			pass
		else:
			if get_student_by_index(i).is_present:
				spread_indicies.append(i)
				#print(i, " is NOT adjacent to ", student_index)
	return spread_indicies
	
# is index1 adjacent to index2
func is_adjacent_index(index1, index2):
	#up
	if (not is_top_row_index(index2)) and index2 - cols_of_desks == index1:
		return true
	#down
	if (not is_bottom_row_index(index2)) and index2 + cols_of_desks == index1:
		return true
	#left
	if (not is_left_col_index(index2)) and index2 - 1 == index1:
		return true
	#right
	if (not is_right_col_index(index2)) and index2 + 1 == index1:
		return true
	#up left
	if (not (is_top_row_index(index2) or is_left_col_index(index2))) and index2 - cols_of_desks - 1 == index1:
		return true
	#up right
	if (not (is_top_row_index(index2) or is_right_col_index(index2))) and index2 - cols_of_desks + 1 == index1:
		return true
	#down left
	if (not (is_bottom_row_index(index2) or is_left_col_index(index2))) and index2 + cols_of_desks - 1 == index1:
		return true
	#down right
	if (not (is_bottom_row_index(index2) or is_right_col_index(index2))) and index2 + cols_of_desks + 1 == index1:
		return true
	return false
	
func is_top_row_index(index):
	return rows_of_desks == 1 or index / cols_of_desks == 0

func is_bottom_row_index(index):
	return rows_of_desks == 1 or index / cols_of_desks == rows_of_desks - 1

func is_right_col_index(index):
	return index % cols_of_desks == cols_of_desks - 1
	
func is_left_col_index(index):
	return index % cols_of_desks == 0

func pop_random(array):
	return array.pop_at(randi_range(0, array.size()-1))
			
func prepare_student(student, index):
	student.index = index
	student.accused_of_cheating.connect(_on_student_accused.bind(index))
	student.get_node("Timer").timeout.connect(_on_student_requests_action.bind(student))
	start_random_action_random_wait(student)
			
func start_random_action_random_wait(student, fixed_cheat_time = true):
	var random_action = range(Actions.size()).pick_random()
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
		print("Student ", student_index, " taking action ", Actions.find_key(picked_action), " in ", wait_before_action,  "seconds. CHEATING = ", should_cheat)
			
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
		
func get_student_by_index(index) -> Student:
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
		Actions.LOOK_DOWN, Actions.LOOK_FORWARD, Actions.COUGH:
			return false
		Actions.LOOK_LEFT:
			return has_neighbor_left(student.index)
		Actions.LOOK_RIGHT:
			return has_neighbor_right(student.index)
		Actions.TALK:
			return has_any_neighbor(student.index)
			
func has_neighbor_left(student_index):
	if student_index % cols_of_desks == 0:
		return false
	return get_student_by_index(student_index - 1).is_present
	
func has_neighbor_right(student_index):
	if student_index % cols_of_desks == cols_of_desks - 1:
		return false
	return get_student_by_index(student_index + 1).is_present
	
func has_neighbor_up(student_index):
	if rows_of_desks == 1 or student_index / cols_of_desks == 0:
		return false
	return get_student_by_index(student_index - cols_of_desks).is_present
	
func has_neighbor_down(student_index):
	if rows_of_desks == 1 or student_index / cols_of_desks == rows_of_desks - 1:
		return false
	return get_student_by_index(student_index + cols_of_desks).is_present
	
func has_any_neighbor(student_index):
	return has_neighbor_down(student_index) or has_neighbor_up(student_index) or has_neighbor_left(student_index) or has_neighbor_right(student_index)

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
		start_action_random_wait(student, Actions.LOOK_DOWN)
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
