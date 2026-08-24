extends Node2D

var unlocks = {2: false, 3: false}

func _ready() -> void:
	add_to_group("UnlockTracker")

func _on_level_complete(unlock):
	unlocks[unlock+1] = true
