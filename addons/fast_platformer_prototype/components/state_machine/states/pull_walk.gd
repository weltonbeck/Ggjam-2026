extends State


# nome do state
func _state_name() -> String:
	return "pull_walk"

# Função chamada a cada frame de física (para lógicas dependentes da física)
func _on_state_physics_process(delta : float) -> void:
	if behavior:
		var _input = behavior._horizontal_input
		var is_on_limit = false
		#verifica se ele nao vai se esmagar
		if behavior.test_move_left_right() and ((behavior.is_pushable_platformer_on_right() and _input < 0) or (behavior.is_pushable_platformer_on_left() and _input > 0)):
			_input = 0
			is_on_limit = true
		behavior.horizontal_movement(delta, _input, behavior.max_speed / 2)		
		if behavior.has_method("handle_gravity") and behavior.has_method("handle_slope_slide"):
			behavior.handle_gravity(delta)
			behavior.handle_slope_slide(delta)
		else:
			behavior.vertical_movement(delta, behavior._vertical_input, behavior.max_speed / 2)
		
		
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
		elif state_machine.has_state("push_walk") and behavior.is_able_to_move() and behavior.has_method("is_able_to_push_wall") and behavior.is_able_to_push_wall() and behavior.has_method("is_able_to_pull_wall") and not behavior.is_able_to_pull_wall():
			transition_to("push_walk")
		elif behavior.is_able_to_stop() and behavior.has_method("is_able_to_push_wall") and behavior.is_able_to_push_wall():
			behavior._last_horizontal_input *= -1
			transition_to("push_idle")
		elif state_machine.has_state("run") and behavior.is_able_to_move() and behavior.has_method("is_able_to_push_wall") and not behavior.is_able_to_push_wall():
			transition_to("run")
		elif behavior.is_able_to_stop():
			transition_to("idle")
