class_name SpriteManager
extends Node2D

const MOUTH_CLOSED = preload("res://Images/mouth.png")
const MOUTH_OPEN = preload("res://Images/open_mouth.png")

static func change_sprite(sprite, texture):
	sprite.texture = texture
