extends SimplePatrolPlaformerBehavior
class_name Enemy

var _shoot:bool = false

@onready var state_look: State = $StateMachine/Look
@onready var state_lose_player: Node = $StateMachine/LosePlayer

@export var stone_scene: PackedScene

var max_shoot_time = 5
var max_shoot_timer = 0

func _process_inputs(delta: float) -> void:
	if is_shooting():
		_walk = false
		set_shoot_input(true)
		
		if max_shoot_timer > 0:
			max_shoot_timer -= delta
			if max_shoot_timer <= 0:
				lose_player()
	else:
		set_shoot_input(false)
		
	super._process_inputs(delta)

func lose_player() -> void:
	stop_shoot()
	_walk = walk
	state_lose_player.transition_to_state()

func _on_player_entered(_player:CharacterBehavior) -> void:
	state_look.transition_to_state()
		
func _on_player_exited(_player:CharacterBehavior) -> void:
	if stop_after_time:
		loose_player = true
		stop_after_timer = stop_after_time

func start_shoot() -> void:
	_shoot = true
	max_shoot_timer = max_shoot_time

func stop_shoot() -> void:
	_shoot = false

func is_shooting() -> bool:
	return _shoot

func turn_stone() -> void:
	if stone_scene:
		var _instance = stone_scene.instantiate()
		get_tree().root.call_deferred("add_child", _instance)
		_instance.global_position = global_position
		call_deferred("queue_free")
