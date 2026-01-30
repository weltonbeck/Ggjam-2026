extends State

@export var edge_fall_velocity:float = 50 ## velocidade da queda

var edge_direction:int

# nome do state
func _state_name() -> String:
	return "fall_on_edge"

# Função chamada a cada frame de física (para lógicas dependentes da física)
func _on_state_physics_process(delta : float) -> void:
	if behavior and behavior is CharacterPlaformerBehavior:
		behavior.velocity.x = edge_fall_velocity * edge_direction
		behavior.handle_gravity(delta)
		behavior.do_move_and_slide()

# Função que define as condições para transições entre estados
func _on_state_next_transitions() -> void:
	if behavior and behavior is CharacterPlaformerBehavior:
		if behavior.is_in_slope() or (behavior.is_on_floor() and behavior.is_on_rc_floor_center()):
			transition_to("idle")
		elif state_machine.has_state("fall") and behavior.has_method("is_able_to_fall") and behavior.is_able_to_fall():
			transition_to("fall")

# Função que define as condições para transições entre estados
func _on_state_check_transitions(current_state_name:String, _current_state:Node) -> void:
	if behavior:
		if current_state_name in ["idle"] and is_on_edge() and behavior.is_able_to_stop():
			#print("is_on_wall ",behavior.is_on_wall() )
			#print("is_on_rc_wall ",behavior.is_on_rc_wall() )
			if not behavior.is_on_rc_floor_center() and not behavior.is_in_slope():
				transition_to_me()

# Função chamada ao entrar neste estado
func _on_state_enter(_last_state_name:String) -> void:
	edge_direction = get_edge_direction()

func is_on_edge() -> bool:
	if behavior:
		var _is_on_rc_floor_right_edge = behavior.is_on_rc_floor_right_edge() 
		var _is_on_rc_floor_left_edge =  behavior.is_on_rc_floor_left_edge()
		print("_is_on_rc_floor_right_edge",_is_on_rc_floor_right_edge) 
		print("_is_on_rc_floor_left_edge",_is_on_rc_floor_left_edge) 
		
		return _is_on_rc_floor_right_edge != _is_on_rc_floor_left_edge and (_is_on_rc_floor_right_edge or _is_on_rc_floor_left_edge)
	return false

func get_edge_direction() -> int:
	if behavior and behavior.is_on_rc_floor_right_edge():
		return 1
	return -1
