extends State

@export var life_points: LifePoints
@export var push_force: float = 250

var hurt_direction:Vector2 = Vector2.ZERO

# nome do state
func _state_name() -> String:
	return "die"

func _ready() -> void:
	if life_points:
		life_points.take_damage.connect(_on_take_damage)
		life_points.die.connect(_on_die)

func _on_take_damage(_amount:float, _diretion:Vector2) -> void:
	hurt_direction = _diretion
	if behavior and behavior is CharacterPlaformerBehavior:
		if _diretion.x > 0:
			hurt_direction = Vector2(1,0)
		elif _diretion.x < 0:
			hurt_direction = Vector2(-1,0)

func _on_die() -> void:
	if behavior:
		behavior.die()

# Função chamada a cada frame de física (para lógicas dependentes da física)
func _on_state_physics_process(delta : float) -> void:
	if behavior:
		behavior.horizontal_movement(delta,0)
		if behavior.has_method("handle_gravity"):
			behavior.handle_gravity(delta)
		behavior.do_move_and_slide()

# Função que define as condições para transições entre estados
func _on_state_check_transitions(current_state_name:String, _current_state:Node) -> void:
	if behavior and behavior.is_able_to_die():
		if state_machine.current_state_name not in ["die"]:
			transition_to_me()

# Função chamada ao entrar neste estado
func _on_state_enter(_last_state_name:String) -> void:
	if behavior:
		behavior.die()
		if push_force:
			if behavior is CharacterPlaformerBehavior:
				hurt_direction.y = 0
			behavior.velocity = hurt_direction * push_force
