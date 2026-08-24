class_name Classroom
extends Node2D

const STUDENT = preload("res://Scenes/student.tscn")
const STUDENT_WIDTH = 128
const STUDENT_HEIGHT = 200
const SAFE_ACTIONS = [0, 1]

var present_indices = []
var active_cheaters = {}
var successful_cheats = 0
var false_accusations = 0

@export var number_of_students = 8

#Softcap of 5x8
@export_range(1, 5, 1) var rows_of_desks : int = 3
@export_range(1, 8, 1) var cols_of_desks : int = 3

@export var max_random_wait_seconds = 60

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	make_students()
	start_exam()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
		
		
func make_students():
	var area_bounds = $StudentArea/StudentAreaShape.shape.size
	
	#	Determine left right padding for student placement
	#	Desk columns * 2 - 1 to account for vertical walk ways
	var total_horizontal_space = (cols_of_desks*2 - 1) * STUDENT_WIDTH
	var padding = (area_bounds.x - total_horizontal_space)/2
	
	#	Place student scenes
	var current_x_pos = padding
	var current_y_pos = 0
	for row in range(rows_of_desks):
		for col in range(cols_of_desks):
			var student = STUDENT.instantiate()
			student.position = position + Vector2(current_x_pos, current_y_pos)
			$StudentContainer.add_child(student)
			current_x_pos += STUDENT_WIDTH*2
		current_y_pos += STUDENT_HEIGHT
		current_x_pos = padding
	
	#	Remove students to match number_of_students
	var remaining_indices = range(rows_of_desks * cols_of_desks)
	var num_students = min(number_of_students, rows_of_desks * cols_of_desks)
	for i in num_students:
		var random_pick = remaining_indices.pick_random()
		remaining_indices.remove_at(remaining_indices.find(random_pick))
		present_indices.append(random_pick)
	
	for i in range($StudentContainer.get_children().size()):
		var student = $StudentContainer.get_child(i)
		if i not in present_indices:
			student.mark_absent()
		else:
			student.index = i
			student.accused_of_cheating.connect(_on_student_accused.bind(i))
			student.get_node("Timer").timeout.connect(_on_student_requests_action.bind(student))

func start_exam():
	# TODO: post mvp this is where you would trigger picking up pencils
	
	#Start random actions
	for student in $StudentContainer.get_children():
		start_action_random_wait(student, 0)

func start_action_random_wait(student, action):
	student.perform_action(action, randf_range(1,max_random_wait_seconds))

func start_random_action_random_wait(student):
	var random_action = range(4).pick_random()
	if random_action not in SAFE_ACTIONS:
		active_cheaters[student.index] = random_action
	student.perform_action(random_action, randf_range(1,max_random_wait_seconds))
	
func increment_cheat_count():
	successful_cheats += 1
	$CheatsCountText.text = str(successful_cheats)
	
func increment_false_accusations():
	false_accusations += 1
	$FalseAccusationCountText.text = str(false_accusations)

func handle_if_cheating(student):
	if active_cheaters.has(student.index):
		print("Student ", student.index, " cheated with action ", active_cheaters[student.index])
		increment_cheat_count()
		
func get_student_by_index(index):
	return $StudentContainer.get_child(index)

func _on_student_requests_action(student):
	handle_if_cheating(student)
	start_random_action_random_wait(student)

func _on_student_accused(index):
	if active_cheaters.has(index):
		print("Stopped student ", index, " from cheating")
		active_cheaters.erase(index)
		start_action_random_wait(get_student_by_index(index), 0)
	else:
		print("Falsely accused student ", index, " of cheating")
		increment_false_accusations()

func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")
