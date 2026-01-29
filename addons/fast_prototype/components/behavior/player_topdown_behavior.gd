extends CharacterBehavior
class_name PlayerTopDownBehavior


# ------------------------------------------------------------------------------
# Input Configuration
# ------------------------------------------------------------------------------
# Ações de input utilizadas para movimentação.
# Utilizamos StringName para:
# - Melhor performance (comparação por ID)
# - Evitar alocações desnecessárias
# - Padronizar com a API moderna do Godot 4.x
@export_group("Inputs")
@export var key_up:    StringName = &"key_up"
@export var key_down:  StringName = &"key_down"
@export var key_left:  StringName = &"key_left"
@export var key_right: StringName = &"key_right"
@export var key_dash: StringName = &"key_button_a"


# ------------------------------------------------------------------------------
# Input Processing
# ------------------------------------------------------------------------------
## Processa o input de movimentação do jogador.
## Este método:
## - Lê os eixos horizontal e vertical via InputMap
## - Constrói um vetor de direção normalizado
## - Encaminha o input para o sistema base de movimento
func _process_inputs(delta: float) -> void:
	if not InputMap.has_action(key_left) or not InputMap.has_action(key_right) or not InputMap.has_action(key_up)or not InputMap.has_action(key_down):
		return
	
	if InputMap.has_action(key_up) and InputMap.has_action(key_down) and InputMap.has_action(key_left) and InputMap.has_action(key_right):
		# Obtém o eixo vertical (cima / baixo)
		var input_y := Input.get_axis(key_up, key_down)

		# Obtém o eixo horizontal (esquerda / direita)
		var input_x := Input.get_axis(key_left, key_right)

		# Combina os eixos em um vetor de input
		var input_vector := Vector2(input_x, input_y)

		# Encaminha o input para o CharacterBehavior
		set_input(input_vector)
	
	if key_dash and InputMap.has_action(key_dash):
		set_input_dash(Input.is_action_just_pressed(key_dash))
