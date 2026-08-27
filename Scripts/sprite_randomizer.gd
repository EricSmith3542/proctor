extends Sprite2D

@export var possible_sprites : Array[Texture2D]
@export var is_optional := false

func _ready() -> void:
	var possiblities = possible_sprites
	if is_optional:
		possiblities.append(null)
	texture = possiblities.pick_random()
	#if texture:
		#position += Vector2(0, 128 - texture.get_height())
