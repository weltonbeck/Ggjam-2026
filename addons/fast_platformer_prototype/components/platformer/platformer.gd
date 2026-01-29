class_name PlatformerComponent
extends Node2D

@export var one_way_platformer:bool = true ## é uma platforma one_way

func _ready() -> void:
	add_to_group(Globals.GROUP_PLATFORMER)
	
	if one_way_platformer:
		add_to_group(Globals.GROUP_THROUGH_PLATFORMER)
		## procura um collision e fala q ele é one_way
		for child in get_children():
			if child is CollisionShape2D:
				child.one_way_collision = one_way_platformer
