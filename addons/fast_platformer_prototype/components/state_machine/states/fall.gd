extends State

# nome do state
func _state_name() -> String:
	return "fall"

# Função chamada a cada frame de física (para lógicas dependentes da física)
func _on_state_physics_process(delta : float) -> void:
	if behavior and behavior is CharacterPlaformerBehavior:
		behavior.horizontal_movement(delta)
		behavior.handle_gravity(delta)
		behavior.do_move_and_slide()


# Função que define as condições para transições entre estados
func _on_state_next_transitions() -> void:
	if behavior and behavior is CharacterPlaformerBehavior: 
		if state_machine.has_state("jump") and behavior.is_able_to_jump():
			transition_to("jump")
		elif state_machine.has_state("double_jump") and behavior.is_able_to_double_jump():
			transition_to("double_jump")
		elif state_machine.has_state("dash") and behavior.is_able_to_dash():
			transition_to("dash")
		elif state_machine.has_state("fast_fall") and behavior.is_able_to_fast_fall():
			transition_to("fast_fall")
		elif state_machine.has_state("land") and  behavior.is_able_to_land():
			transition_to("land")
		elif state_machine.has_state("attack") and behavior.is_able_to_attack():
			transition_to("attack")
		elif state_machine.has_state("idle") and  behavior.is_able_to_land():
			transition_to("idle")
