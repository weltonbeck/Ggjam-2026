extends State

# nome do state
func _state_name() -> String:
	return "run"

# Função chamada a cada frame de física (para lógicas dependentes da física)
func _on_state_physics_process(delta : float) -> void:
	if behavior:
		behavior.horizontal_movement(delta)
		if behavior.has_method("handle_gravity") and behavior.has_method("handle_slope_slide"):
			behavior.handle_gravity(delta)
			behavior.handle_slope_slide(delta)
		else:
			behavior.vertical_movement(delta)
		behavior.do_move_and_slide()
		
	
# Função que define as condições para transições entre estados
func _on_state_next_transitions() -> void:
	if behavior:
		if behavior.has_method("is_able_to_jump") and behavior.is_able_to_jump():
			transition_to("jump")
		elif behavior.has_method("is_able_to_fall") and behavior.is_able_to_fall():
			transition_to("fall")
		elif state_machine.has_state("dash") and behavior.is_able_to_dash():
			transition_to("dash")
		elif state_machine.has_state("attack") and behavior.is_able_to_attack():
			transition_to("attack")
		elif behavior.is_able_to_stop():
			transition_to("idle")
