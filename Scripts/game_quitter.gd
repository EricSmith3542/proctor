extends Node2D


# Called when the node enters the scene tree for the first time.
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		request_quit()

func request_quit():
	get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)
