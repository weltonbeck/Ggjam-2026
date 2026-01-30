@icon("res://addons/fast_prototype/assets/icons/identifier.svg")
extends Node

@export var target:CharacterBody2D

func _ready() -> void:
	if not target and get_parent() is CharacterBehavior:
		target = get_parent()
	set_identifier()

func set_identifier() -> void:
	if target:
		reset_layers()
		target.add_to_group(Globals.GROUP_PLAYER)
		target.set_collision_layer_value(Globals.LAYER_PLAYER, true)
		target.set_collision_mask_value(Globals.LAYER_FLOOR, true)

func reset_layers() -> void:
	if target:
		target.collision_layer = 0
		target.collision_mask = 0
