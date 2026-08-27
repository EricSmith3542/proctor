extends Node2D

var levels_completed = {"k0": false, "k1": false, "k2": false, "e0": false, "e1": false, "e2": false, "m0": false, "m1": false, "m2": false, "h0": false, "h1": false, "h2": false}

func _ready() -> void:
	add_to_group("UnlockTracker")

func _on_level_complete(grade, level):
	levels_completed[str(grade)+str(level)] = true
