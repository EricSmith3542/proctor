extends VFlowContainer

const WIN_TEXT = "Exam Completed"
const WIN_SETTINGS = preload("res://Label Settings/ExamCompleteLabel.tres")

const LOSE_TEXT = "Exam Failed"
const LOSE_SETTINGS = preload("res://Label Settings/ExamFailed.tres")

@onready var win_lose_label := $WinLoseLabel

func set_win_label(is_win):
	if is_win:
		win_lose_label.text = WIN_TEXT
		win_lose_label.label_settings = WIN_SETTINGS
	else:
		win_lose_label.text = LOSE_TEXT
		win_lose_label.label_settings = LOSE_SETTINGS

func set_all_label_values(stopped, accuse, cheats):
	$CheatsStoppedLabel.set_value(stopped)
	$FalseAccusationsLabel.set_value(accuse)
	$CheatSuccessLabel.set_value(cheats)
	
func connect_continue_pressed_signal(method):
	$ContinueButton.pressed.connect(method)
