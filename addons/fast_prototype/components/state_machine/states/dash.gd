extends State

@export_group("Intagible")
@export var life_points: LifePoints

@export_group("Damage")
@export var hit_box:HitBox


# nome do state
func _state_name() -> String:
	return "dash"

func _on_state_ready() -> void:
	if hit_box:
		hit_box.active = false
	if behavior:
		set_animation_tree_blend_param(animation_tree, animation_tree_blend_param,behavior._last_horizontal_input, behavior.get_last_input())

# Função chamada a cada frame de física (para lógicas dependentes da física)
func _on_state_physics_process(delta : float) -> void:
	if behavior:
		behavior.horizontal_movement(delta,0)
		if behavior.has_method("handle_slope_slide"):
			behavior.handle_slope_slide(delta, behavior.velocity.normalized().x)
			if behavior.dash_apply_gravity:
				behavior.handle_gravity(delta)
		else:
			behavior.vertical_movement(delta,0)
		behavior.handle_dash(delta)
		behavior.do_move_and_slide()
		

# Função que define as condições para transições entre estados
func _on_state_next_transitions() -> void:
	if behavior: 
		if state_machine.has_state("jump") and behavior.has_method("is_able_to_jump") and behavior.is_able_to_jump():
			transition_to("jump")
		elif state_machine.has_state("double_jump") and behavior.is_able_to_double_jump():
			transition_to("double_jump")
		elif behavior.is_able_to_stop_dash() and state_machine.has_state("fall") and behavior.has_method("is_able_to_fall") and behavior.is_able_to_fall():
			transition_to("fall")
		elif behavior.is_able_to_stop_dash() and behavior.is_able_to_crouch():
			transition_to("crouch")
		elif behavior.is_able_to_stop_dash() and state_machine.has_state("run") and behavior.is_able_to_move():
			transition_to("run")
		elif behavior.is_able_to_stop_dash() and state_machine.has_state("idle") and behavior.is_able_to_stop():
			transition_to("idle")

func _on_state_enter(_last_state_name: String) -> void:
	if behavior:
		if hit_box:
			hit_box.activate()
		behavior.do_dash()
		if life_points:
			life_points.set_intagible(behavior.dash_duration_time)


func _on_state_exit() -> void:
	if behavior:
		behavior.do_dash_cooldown()
	if hit_box:
		hit_box.deactivate()

func _on_animation_process(_delta: float) -> void:
	if behavior and animation_tree and behavior.velocity != Vector2.ZERO:
		set_animation_tree_blend_param(animation_tree, animation_tree_blend_param, behavior.velocity.normalized().x, behavior.velocity.normalized())
