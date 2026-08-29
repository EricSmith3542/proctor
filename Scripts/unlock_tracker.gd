extends Node2D

var levels_completed:Dictionary[String, int] = {"k0": 0, "k1": 0, "k2": 0, "e0": 0, "e1": 0, "e2": 0, "m0": 0, "m1": 0, "m2": 0, "h0": 0, "h1": 0, "h2": 0}

func _ready() -> void:
	add_to_group("UnlockTracker")

func _on_level_complete(grade, level, score):
	levels_completed[str(grade)+str(level)] = int(max(score, levels_completed[str(grade)+str(level)]))
	SaveManager.save_all()
