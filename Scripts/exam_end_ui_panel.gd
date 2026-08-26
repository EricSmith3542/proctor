extends PanelContainer

@onready var exam_end_ui := $ExamEndUI

func set_win_label(is_win):
	exam_end_ui.set_win_label(is_win)

func set_all_label_values(stopped, accuse, cheats):
	exam_end_ui.set_all_label_values(stopped, accuse, cheats)
	
func connect_continue_pressed_signal(method):
	exam_end_ui.connect_continue_pressed_signal(method)
