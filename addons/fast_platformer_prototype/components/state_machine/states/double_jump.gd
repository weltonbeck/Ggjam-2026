extends State

# nome do state
func _state_name() -> String:
	return "double_jump"

# Função chamada a cada frame de física (para lógicas dependentes da física)
func _on_state_physics_process(delta : float) -> void:
	if behavior:
		behavior.horizontal_movement(delta)
		behavior.handle_jump()
		behavior.handle_gravity(delta)
		behavior.do_move_and_slide()
		

# Função que define as condições para transições entre estados
func _on_state_next_transitions() -> void:
	if behavior: 
		if state_machine.has_state("double_jump") and behavior.is_able_to_double_jump():
			transition_to("double_jump", true)
		elif state_machine.has_state("fall") and behavior.is_able_to_fall():
			transition_to("fall")
		elif state_machine.has_state("dash") and behavior.is_able_to_dash():
			transition_to("dash")
		elif state_machine.has_state("attack") and behavior.is_able_to_attack():
			transition_to("attack")

func _on_state_enter(_last_state_name: String) -> void:
	if behavior:
		behavior.do_jump()
