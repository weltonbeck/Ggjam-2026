@icon("res://addons/fast_prototype/assets/icons/trigger.svg")
extends Node2D

@export var target_block: Block

@export var transmit_limit:int = 2 ## limite de transferencia de força
@export var time_interval: float = 0.1 ## tempo entre um bloco e outro ativar

@export var four_directions: bool = false ## dispara para as quatro direções

@export_group("Raycasts")
@export var rc_up: RayCast2D ## raycast de cima
@export var rc_down: RayCast2D ## raycast de baixo
@export var rc_left: RayCast2D ## raycast da esquerda
@export var rc_right: RayCast2D ## raycast da direita

## Sinal emitido sempre que o trigger é ativado.
## Pode ser usado por outros sistemas (ex: VFX, som, lógica extra).
signal triggered

func _ready() -> void:
	if target_block:
		target_block.hited.connect(_on_hited)


## Executado quando o sinal monitorado é disparado.
func _on_hited(direction:Vector2, _transmit_limit:int) -> void:
	if _transmit_limit < 0:
		_transmit_limit = transmit_limit
	
	if _transmit_limit != 0 or four_directions:
		_transmit_limit -= 1
		# Emite o sinal interno para outros sistemas escutarem.
		triggered.emit()
		
		if four_directions:
			_transmit_limit = transmit_limit - 1
			transmit(Vector2.UP, _transmit_limit )
			transmit(Vector2.DOWN, _transmit_limit )
			transmit(Vector2.LEFT, _transmit_limit )
			transmit(Vector2.RIGHT, _transmit_limit )
		else:	
			transmit(direction, _transmit_limit )

func transmit(direction: Vector2, _transmit_limit: int) -> void:
	var collision:Object
	if rc_up and direction == Vector2.UP and rc_up.is_colliding():
		collision = rc_up.get_collider()
	elif rc_down and direction == Vector2.DOWN and rc_down.is_colliding():
		collision = rc_down.get_collider()
	elif rc_left and direction == Vector2.LEFT and rc_left.is_colliding():
		collision = rc_left.get_collider()
	elif rc_right and direction == Vector2.RIGHT and rc_right.is_colliding():
		collision = rc_right.get_collider()
				
	if collision and collision.is_in_group(Globals.GROUP_BLOCK) and collision is Block and collision.is_hitable():
		if time_interval:
			await get_tree().create_timer(time_interval, false).timeout
		collision.block_hit(direction, _transmit_limit)
