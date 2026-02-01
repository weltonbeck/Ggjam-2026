extends State

var call_state:bool = false

# nome do state
func _state_name() -> String:
	return "lose_player"

func transition_to_state() -> void:
	call_state = true

# Função chamada a cada frame de física (para lógicas dependentes da física)
func _on_state_physics_process(delta : float) -> void:
	if behavior:
		behavior.horizontal_movement(delta,0)
		behavior.handle_gravity(delta)
		behavior.do_move_and_slide()

# Função que define as condições para transições entre estados
func _on_state_check_transitions(_current_state_name:String, _current_state:Node) -> void:
	if behavior and call_state:
		if behavior is SimplePatrolPlaformerBehavior and not behavior.is_shooting():
			if state_machine.current_state_name not in ["hurt","die"]:
				transition_to_me()

# Função chamada ao entrar neste estado
func _on_state_enter(_last_state_name:String) -> void:
	call_state = false
	
	await get_tree().process_frame
	if animated_sprite:
		await animated_sprite.animation_finished

	if state_machine:
		state_machine.transition_to("idle")

		
