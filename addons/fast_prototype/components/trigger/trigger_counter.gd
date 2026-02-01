@icon("res://addons/fast_prototype/assets/icons/trigger.svg")
extends Node2D

@export var total_trigger_count: int = 2
var current_trigger_count: int = 0

signal trigger_active

func add_to_trigger_count() -> void:
	current_trigger_count += 1
	check_total()
	
func check_total() -> void:
	if current_trigger_count >= total_trigger_count:
		trigger_active.emit()
