extends State

@export var life_points: LifePoints

@export var push_force: float = 150
@export var time_interval:float = 0.2

var _is_hurted: bool = false
var hurt_direction:Vector2 = Vector2.ZERO

# nome do state
func _state_name() -> String:
	return "hurt"

func _ready() -> void:
	if life_points:
		life_points.take_damage.connect(_on_take_damage)

func _on_take_damage(_amount:float, _diretion:Vector2) -> void:
	_is_hurted = true
	hurt_direction = _diretion
	if behavior and behavior is CharacterPlaformerBehavior:
		if _diretion.x > 0:
			hurt_direction = Vector2(1,0)
		elif _diretion.x < 0:
			hurt_direction = Vector2(-1,0)
	
# Função chamada a cada frame de física (para lógicas dependentes da física)
func _on_state_physics_process(delta : float) -> void:
	behavior.horizontal_movement(delta,0)
	if behavior and behavior is CharacterPlaformerBehavior:
		behavior.handle_gravity(delta)
		behavior.do_move_and_slide()

# Função que define as condições para transições entre estados
func _on_state_next_transitions() -> void:
	if behavior and not _is_hurted:
		if state_machine.has_state("idle"):
			transition_to("idle")

# Função que define as condições para transições entre estados
func _on_state_check_transitions(current_state_name:String, _current_state:Node) -> void:
	if behavior and not behavior.is_able_to_die() and _is_hurted:
		if state_machine.current_state_name not in ["hurt"]:
			transition_to_me()

# Função chamada ao entrar neste estado
func _on_state_enter(_last_state_name:String) -> void:
	if behavior and push_force:
		if behavior is CharacterPlaformerBehavior:
			hurt_direction.y = 0
		behavior.velocity = hurt_direction * push_force
	await get_tree().create_timer(time_interval, false).timeout
	_is_hurted = false

func _on_animation_process(_delta: float) -> void:
	if state_machine.current_state._state_name() != _state_name():
		super._on_animation_process(_delta)
