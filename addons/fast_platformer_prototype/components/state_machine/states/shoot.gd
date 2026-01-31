extends State

@export var duration_time:float = 0.25
@export var await_to_shoot:float = 0.2

func _on_state_ready() -> void:
	pass

# nome do state
func _state_name() -> String:
	return "shoot"

# Função chamada a cada frame de física (para lógicas dependentes da física)
func _on_state_physics_process(delta : float) -> void:
	if behavior:
		behavior.horizontal_movement(delta,0)
		if behavior.has_method("handle_gravity") and behavior.has_method("handle_slope_slide"):
			behavior.handle_gravity(delta)
			behavior.handle_slope_slide(delta)
		behavior.do_move_and_slide()

func _on_state_enter(_last_state_name: String) -> void:
	shoot()	
	await get_tree().create_timer(duration_time, false).timeout
	if state_machine.has_state("idle") and state_machine.current_state._state_name() == _state_name():
		transition_to("idle")

func shoot() -> void:
	if behavior:
		if await_to_shoot:
			await get_tree().create_timer(await_to_shoot, false).timeout
		behavior.do_shoot()
