extends State

@export var finish_animation_name:String = "put_mask_finish"
@export var texture_unmasked:SpriteFrames
@export var texture_masked:SpriteFrames

var call_state: bool = false
var unmasked:bool = true

# nome do state
func _state_name() -> String:
	return "mask"

#func _ready() -> void:
	#if life_points:
		#life_points.die.connect(_on_die)

func set_mask_buton(_button:bool) -> void:
	if _button:
		call_state = true

# Função chamada a cada frame de física (para lógicas dependentes da física)
func _on_state_physics_process(delta : float) -> void:
	if behavior:
		behavior.horizontal_movement(delta,0)
		behavior.do_move_and_slide()

# Função que define as condições para transições entre estados
func _on_state_check_transitions(current_state_name:String, _current_state:Node) -> void:
	if behavior and call_state:
		if behavior.is_on_floor() and behavior.is_able_to_stop() and state_machine.current_state_name not in ["hurt","die","dash"]:
			transition_to_me()

# Função chamada ao entrar neste estado
func _on_state_enter(_last_state_name:String) -> void:
	call_state = false
	
	await get_tree().process_frame
	if animated_sprite:
		await animated_sprite.animation_finished
		change_texture()
		

func change_texture() -> void:
	if animated_sprite and texture_unmasked and texture_masked:
		if unmasked:
			unmasked = false
			animated_sprite.sprite_frames = texture_masked
		else:
			unmasked = true
			animated_sprite.sprite_frames = texture_unmasked
	if finish_animation_name:
		animated_sprite_travel(animated_sprite,finish_animation_name)
	
	if state_machine and animated_sprite:
		await animated_sprite.animation_finished
		state_machine.transition_to("idle")
		
