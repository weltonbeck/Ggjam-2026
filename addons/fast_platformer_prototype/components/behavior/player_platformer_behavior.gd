extends CharacterPlaformerBehavior
class_name PlayerPlaformerBehavior


# ------------------------------------------------------------------------------
# Input Configuration
# ------------------------------------------------------------------------------
# Ações de input utilizadas pelo player de plataforma.
# Utilizamos StringName para:
# - Melhor performance (lookup por ID interno)
# - Evitar alocações desnecessárias a cada frame
# - Garantir compatibilidade com o padrão moderno do Godot 4.x
@export_group("Inputs")
@export var key_left:  StringName = &"key_left"
@export var key_right: StringName = &"key_right"
@export var key_up:  StringName = &"key_up"
@export var key_down:  StringName = &"key_down"
@export var key_jump:  StringName = &"key_button_a"
@export var key_dash: StringName = &"key_button_b"
@export var key_fast_fall:  StringName = &"key_down"
@export var key_crouch:  StringName = &"key_down"
@export var key_pull:  StringName = &"key_button_x"
@export var key_attack:  StringName = &"key_button_x"
@export var key_shoot:  StringName = &"key_button_y"

# ------------------------------------------------------------------------------
# Input Processing
# ------------------------------------------------------------------------------
## Processa os inputs do jogador para movimentação e pulo.
## Este método:
## - Lê o eixo horizontal (esquerda / direita)
## - Encaminha o input para o sistema base de movimento
## - Controla o estado de input do pulo (pressionado e segurado)
func _process_inputs(delta: float) -> void:
	if not InputMap.has_action(key_left) or not InputMap.has_action(key_right) or not InputMap.has_action(key_jump):
		return
	
	# --------------------------------------------------------------------------
	# Horizontal Movement
	# --------------------------------------------------------------------------
	# Obtém o eixo horizontal baseado nas actions configuradas
	if InputMap.has_action(key_left) and InputMap.has_action(key_right):
		var input_x := Input.get_axis(key_left, key_right)

		# Encaminha o input horizontal para o CharacterPlaformerBehavior
		set_horizontal_input(input_x)
	
	# --------------------------------------------------------------------------
	# Vertical Movement
	# --------------------------------------------------------------------------
	if InputMap.has_action(key_up) and InputMap.has_action(key_down):
		# Obtém o eixo horizontal baseado nas actions configuradas
		var input_y := Input.get_axis(key_up, key_down)

		# Encaminha o input vertical para o CharacterPlaformerBehavior
		set_vertical_input(input_y)


	# --------------------------------------------------------------------------
	# Jump Input
	# --------------------------------------------------------------------------
	if not key_jump.is_empty() and InputMap.has_action(key_jump):
		# Detecta o momento exato em que o botão de pulo foi pressionado
		set_jump_input(Input.is_action_just_pressed(key_jump))

		# Detecta se o botão de pulo está sendo mantido pressionado
		# (usado para pulo variável / corte de pulo)
		set_jump_input_pressed(Input.is_action_pressed(key_jump))
	
	if not key_dash.is_empty() and InputMap.has_action(key_dash):
		set_input_dash(Input.is_action_just_pressed(key_dash))
	
	if not key_fast_fall.is_empty() and InputMap.has_action(key_fast_fall):
		set_fast_fall_input_pressed(Input.is_action_pressed(key_fast_fall), delta)
	
	if not key_crouch.is_empty() and InputMap.has_action(key_crouch):
		set_crouch_input_pressed(Input.is_action_pressed(key_crouch))
	
	if not key_pull.is_empty() and InputMap.has_action(key_pull):
		set_pull_input_pressed(Input.is_action_just_pressed(key_pull) or Input.is_action_pressed(key_pull))
	
	if not key_attack.is_empty() and InputMap.has_action(key_attack):
		set_attack_input(Input.is_action_just_pressed(key_attack))
	
	if not key_shoot.is_empty() and InputMap.has_action(key_shoot):
		set_shoot_input(Input.is_action_just_pressed(key_shoot))
