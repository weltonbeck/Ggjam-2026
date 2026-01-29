extends State

@export var fast_fall_force: float = 500
@export var fix_edge_fall_velocity:float = 50 ## velocidade da queda


var edge_direction:int

# nome do state
func _state_name() -> String:
	return "fast_fall"

# Função chamada a cada frame de física (para lógicas dependentes da física)
func _on_state_physics_process(delta : float) -> void:
	behavior.horizontal_movement(delta,0)
	if behavior and behavior is CharacterPlaformerBehavior:
		behavior.handle_gravity(delta)
		behavior.do_move_and_slide()

# Função que define as condições para transições entre estados
func _on_state_next_transitions() -> void:
	if behavior and behavior is CharacterPlaformerBehavior:
		if behavior._force_jump:
			transition_to("jump")
		if behavior.is_on_floor() and not behavior.is_on_rc_floor_center() and (behavior.is_on_rc_floor_right_edge() or behavior.is_on_rc_floor_left_edge()):
			behavior.velocity.x = fix_edge_fall_velocity * get_edge_direction()
			transition_to("fall")
		elif state_machine.has_state("land") and behavior.is_able_to_land():
			transition_to("land", true)
		elif state_machine.has_state("idle") and behavior.is_able_to_land():
			transition_to("idle")


# Função chamada ao entrar neste estado
func _on_state_enter(_last_state_name:String) -> void:
	if behavior and behavior.velocity.y < fast_fall_force:
		behavior.velocity.y = fast_fall_force


func get_edge_direction() -> int:
	if behavior and behavior.is_on_rc_floor_right_edge():
		return 1
	return -1
