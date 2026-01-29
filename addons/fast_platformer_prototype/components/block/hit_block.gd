class_name HitBlock
extends Area2D

@export var state:State ## state que ativa o hit

enum Directions {UP,DOWN,LEFT,RIGHT}

@export var direction:Directions = Directions.UP ## direção do impacto
@export var time_interval: float = 0.05 ## tempo entre um bloco e outro ativar

var _collision_shape:CollisionShape2D

var _active: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	if state:
		state.state_enter.connect(_on_state_enter)
		state.state_exit.connect(_on_state_exit)
		
	_collision_shape = NodetHelper.get_first_of_type_by_classname(self, CollisionShape2D)
	
var blocks:Array[Block]

func _on_state_enter(last_state_name: String) -> void:
	_active = true
	
func _on_state_exit() -> void:
	_active = false
	
func _physics_process(_delta: float) -> void:
	if _active:
		var _blocks = blocks.duplicate()
		blocks.clear()
		var closer_block:Block
		var distance_block:float
		for b in _blocks:
			if b:
				if _collision_shape:
					var b_distance = b.global_position.distance_to(_collision_shape.global_position)
					if not distance_block or b_distance < distance_block:
						distance_block = b_distance
						closer_block = b
		if closer_block:
			closer_block.block_hit(get_direction())
			if time_interval:
				await get_tree().create_timer(time_interval, false).timeout
		for b in _blocks:
			if b and b != closer_block:
				b.block_hit(get_direction())

func _on_body_entered(body:Node2D) -> void:
	if body.is_in_group(Globals.GROUP_BLOCK) and body is Block and body.is_hitable():
		blocks.append(body)
		

func _on_body_exited(body:Node2D) -> void:
	if body.is_in_group(Globals.GROUP_BLOCK) and body is Block:
		var _blocks = blocks.duplicate()
		blocks.clear()
		for b in _blocks:
			if b != body:
				blocks.append(b)

func get_direction() -> Vector2:
	var vector_direction = Vector2.UP
	if direction == Directions.DOWN:
		vector_direction = Vector2.DOWN
	elif direction == Directions.LEFT:
		vector_direction = Vector2.LEFT
	elif direction == Directions.RIGHT:
		vector_direction = Vector2.RIGHT
	
	return vector_direction
