class_name Classroom
extends Node2D

const STUDENT = preload("res://Scenes/student.tscn")
const STUDENT_WIDTH = 128
const STUDENT_HEIGHT = 200

var present_indices = []

@export var number_of_students = 8

#Softcap of 5x8
@export_range(1, 5, 1) var rows_of_desks : int = 3
@export_range(1, 8, 1) var cols_of_desks : int = 3

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
			student.accused_of_cheating.connect(_on_student_accused.bind(i))
			student.get_node("Timer").timeout.connect(_on_student_requests_action.bind(student))

func start_exam():
	# TODO: post mvp this is where you would trigger picking up pencils
	
	#Start random actions
	for student in $StudentContainer.get_children():
		start_action_random_wait(student, 0)

func start_action_random_wait(student, action):
	student.perform_action(action, randf_range(1,60))

func start_random_action_random_wait(student):
	student.perform_action(range(4).pick_random(), randf_range(1,60))

func _on_student_requests_action(student):
	start_random_action_random_wait(student)

func _on_student_accused(index):
	print(index, "Accused")
