extends State


# nome do state
func _state_name() -> String:
	return "push_walk"

# Função chamada a cada frame de física (para lógicas dependentes da física)
func _on_state_physics_process(delta : float) -> void:
	if behavior:
		behavior.horizontal_movement(delta, behavior._horizontal_input, behavior.max_speed / 2)
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
		elif state_machine.has_state("attack") and behavior.is_able_to_attack():
			transition_to("attack")
		elif state_machine.has_state("run") and behavior.is_able_to_move() and behavior.has_method("is_able_to_push_wall") and not behavior.is_able_to_push_wall():
			transition_to("run")
		elif behavior.is_able_to_stop() and behavior.has_method("is_able_to_push_wall") and behavior.is_able_to_push_wall():
			transition_to("push_idle")
		elif behavior.is_able_to_stop():
			transition_to("idle")
		

#func _on_state_exit() -> void:
	#if behavior:
		#behavior.clear_current_pushable_platformer()
