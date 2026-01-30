extends State

# nome do state
func _state_name() -> String:
	return "crouch"
	
# Função chamada a cada frame de física (para lógicas dependentes da física)
func _on_state_physics_process(delta : float) -> void:
	if behavior:
		behavior.horizontal_movement(delta,0)
		behavior.handle_gravity(delta)
		behavior.handle_slope_slide(delta)
		behavior.do_move_and_slide()

# Função que define as condições para transições entre estados
func _on_state_next_transitions() -> void:
	if behavior:
		if state_machine.has_state("fall") and behavior.has_method("is_able_to_fall") and behavior.is_able_to_fall():
			transition_to("fall")
		elif state_machine.has_state("run") and behavior.is_able_to_move() and not behavior.is_crouch_input_pressed():
			transition_to("run")
		elif not behavior.is_able_to_crouch() and behavior.is_able_to_stop():
			transition_to("idle")


func _on_animation_process(_delta: float) -> void:
	if state_machine and state_machine.current_state_name != _state_name():
		super._on_animation_process(_delta)
