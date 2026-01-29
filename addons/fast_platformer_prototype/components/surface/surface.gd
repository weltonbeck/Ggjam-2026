extends Node2D
class_name Surface
	
@export_range(-1,1,0.1) var surface_speed_multiply_factor: float = 0 ## valor da velocidade do chão
@export_range(-1,1,0.1) var surface_friction_multiply_factor:float = 0 ## valor da fricção do chão
@export_range(0,2,0.1) var surface_bounce_multiply_factor:float = 0 ## valor do quicar
@export_range(0,1,0.1) var surface_jump_multiply_stickiness: float = 0 ## valor de grudar do pulo
@export var surface_automatic_speed: float = 0.0 ## valor da velocidade automatica do chão

signal character_touched(character:CharacterBehavior) ## quando o character tocar o sinal

func _ready() -> void:
	add_to_group(Globals.GROUP_SURFACE)
