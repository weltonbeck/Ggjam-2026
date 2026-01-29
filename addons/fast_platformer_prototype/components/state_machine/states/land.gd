extends State

@export var min_fall_force: float = 500
@export var duration_time:float = 0.2

# nome do state
func _state_name() -> String:
	return "land"
	
# Função chamada a cada frame de física (para lógicas dependentes da física)
func _on_state_physics_process(delta : float) -> void:
	if behavior:
		behavior.horizontal_movement(delta,0)
		behavior.handle_gravity(delta)
		behavior.do_move_and_slide()

func _on_state_enter(_last_state_name: String) -> void:
	await get_tree().process_frame
	if not behavior._force_jump:
		await get_tree().create_timer(duration_time, false).timeout
	if state_machine.has_state("idle") and state_machine.current_state._state_name()  == _state_name():
		transition_to("idle")

func _on_animation_process(_delta: float) -> void:
	pass

func _can_enter(_previous_state_name: String, _previous_state: State, _force:bool = false) -> Dictionary:
	var allowed = false
	if  behavior and  (_force or behavior.is_able_to_super_land(min_fall_force)):
		set_animation_tree_blend_param(animation_tree, animation_blend_param,behavior._last_horizontal_input, behavior.get_last_input())
		allowed = true
	return {
		"allowed": allowed,
		"redirect": "idle"
	}
