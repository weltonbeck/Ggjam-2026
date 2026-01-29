extends State

@export var duration_time:float = 0.25
@export var hit_box:HitBox

func _on_state_ready() -> void:
	if hit_box:
		hit_box.active = false

# nome do state
func _state_name() -> String:
	return "attack"
	
# Função chamada a cada frame de física (para lógicas dependentes da física)
func _on_state_physics_process(delta : float) -> void:
	if behavior:
		behavior.horizontal_movement(delta,0)
		if behavior.has_method("handle_gravity") and behavior.has_method("handle_slope_slide"):
			behavior.handle_gravity(delta)
			behavior.handle_slope_slide(delta)
		else:
			behavior.vertical_movement(delta,0)
		behavior.do_move_and_slide()

func _on_state_enter(_last_state_name: String) -> void:
	await get_tree().process_frame
	if hit_box:
		hit_box.activate()
	await get_tree().create_timer(duration_time, false).timeout
	if hit_box:
		hit_box.deactivate()
	if state_machine.has_state("idle") and state_machine.current_state._state_name() == _state_name():
		transition_to("idle")

func _on_animation_process(_delta: float) -> void:
	if state_machine.current_state._state_name() != _state_name():
		super._on_animation_process(_delta)
		
