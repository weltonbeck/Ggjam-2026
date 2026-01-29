extends State

@export var life_points: LifePoints
@export var delay_time:float = 0.1

var _is_die: bool = false

# nome do state
func _state_name() -> String:
	return "die"

func _ready() -> void:
	if life_points:
		life_points.die.connect(_on_die)

func _on_die() -> void:
	await get_tree().create_timer(delay_time, false).timeout
	_is_die = true

# Função chamada a cada frame de física (para lógicas dependentes da física)
func _on_state_physics_process(delta : float) -> void:
	pass

# Função que define as condições para transições entre estados
func _on_state_next_transitions() -> void:
	pass

# Função que define as condições para transições entre estados
func _on_state_check_transitions(current_state_name:String, _current_state:Node) -> void:
	if behavior and _is_die:
		if state_machine.current_state not in ["die"]:
			transition_to_me()

# Função chamada ao entrar neste estado
func _on_state_enter(_last_state_name:String) -> void:
	_is_die = false
	await get_tree().process_frame
	if behavior:
		behavior.call_deferred("queue_free")
