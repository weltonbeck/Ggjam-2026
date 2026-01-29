@tool
extends Puppeteer
class_name InputSequencePuppeteer

## ===========================================================
##  INPUT SEQUENCE PUPPETEER
## -----------------------------------------------------------
##  Executa uma sequência determinística de inputs sobre um
##  CharacterBehavior, útil para:
##   - cutscenes
##   - replays
##   - testes automatizados
##   - IA scripted
##
##  Cada item da sequência define:
##   - ações ativas (flags)
##   - duração em segundos
##
##  O script funciona tanto em runtime quanto no editor (@tool).
## ===========================================================


# ===========================================================
# ENUMS
# ===========================================================

## Ações disponíveis para a sequência de inputs
enum InputAction {
	MOVE_LEFT,
	MOVE_RIGHT,
	MOVE_UP,
	MOVE_DOWN,
	JUMP,
	DASH
}


# ===========================================================
# EXPORTED CONFIG
# ===========================================================

## Se verdadeiro, a sequência reinicia ao chegar ao final
@export var loop_sequence: bool = false


# ===========================================================
# SEQUENCE DATA (EDITOR-DRIVEN)
# ===========================================================

## Lista de ações por item (armazenadas como string: "MOVE_LEFT,JUMP")
var sequence_actions: Array[String] = []

## Duração (em segundos) de cada item da sequência
var sequence_durations: Array[float] = []


# ===========================================================
# RUNTIME STATE
# ===========================================================

## Índice atual da sequência (-1 = ainda não iniciou)
var _current_step_index: int = -1

## Tempo restante do step atual
var _current_step_time_left: float = 0.0


# ===========================================================
# MAIN UPDATE
# ===========================================================

func _puppeteer_process(delta: float) -> void:
	if sequence_actions.is_empty():
		return

	var active_actions: Array[int] = []

	# Se já estamos em um step válido, interpreta as ações dele
	if _current_step_index >= 0 and _current_step_index < sequence_actions.size():
		active_actions = _parse_action_string(sequence_actions[_current_step_index])

	# Enquanto ainda houver tempo neste step, mantém inputs pressionados
	if _current_step_time_left > 0.0:
		_current_step_time_left -= delta
		_apply_pressed_inputs(active_actions)
		return

	# Step terminou → solta inputs anteriores
	if _current_step_index >= 0:
		_apply_just_released_inputs(active_actions)

	# Avança para o próximo step
	_current_step_index += 1

	# Se ainda há steps válidos, inicializa o próximo
	if _current_step_index < sequence_actions.size():
		active_actions = _parse_action_string(sequence_actions[_current_step_index])
		_current_step_time_left = sequence_durations[_current_step_index]

		_apply_pressed_inputs(active_actions)
		_apply_just_pressed_inputs(active_actions)
		return

	# Fim da sequência
	if loop_sequence:
		finished.emit()
		_current_step_index = -1
	else:
		deactivate()


# ===========================================================
# INPUT APPLICATION
# ===========================================================

## Inputs mantidos pressionados durante o step
func _apply_pressed_inputs(actions: Array[int]) -> void:
	var jump_pressed := false
	var move_left := false
	var move_right := false

	for action in actions:
		match action:
			InputAction.JUMP:
				jump_pressed = true
			InputAction.MOVE_LEFT:
				move_left = true
			InputAction.MOVE_RIGHT:
				move_right = true

	if not target:
		return

	# Jump (hold)
	target.set_jump_input_pressed(jump_pressed)

	# Movimento horizontal
	var input_x := 0
	if move_left and not move_right:
		input_x = -1
	elif move_right and not move_left:
		input_x = 1

	target.set_horizontal_input(input_x)
	
	target.set_jump_input(false)
	target.set_input_dash(false)


## Inputs disparados apenas no início do step
func _apply_just_pressed_inputs(actions: Array[int]) -> void:
	var jump_just_pressed := false
	var dash_just_pressed := false

	for action in actions:
		match action:
			InputAction.JUMP:
				jump_just_pressed = true
			InputAction.DASH:
				dash_just_pressed = true

	if not target:
		return

	target.set_jump_input(jump_just_pressed)
	target.set_input_dash(dash_just_pressed)


## Inputs liberados ao final do step
func _apply_just_released_inputs(_actions: Array[int]) -> void:
	# Placeholder para futuras extensões (ex: soltar dash, soltar ataque)
	pass


# ===========================================================
# PARSING
# ===========================================================

## Converte string "MOVE_LEFT,JUMP" em Array[int] do enum
func _parse_action_string(action_string: String) -> Array[int]:
	var result: Array[int] = []

	for action_name in action_string.split(","):
		action_name = action_name.strip_edges()
		if action_name in InputAction.keys():
			result.append(InputAction[action_name])

	return result


# ===========================================================
# EDITOR PROPERTY OVERRIDES
# ===========================================================

func _get_property_list() -> Array[Dictionary]:
	var properties: Array[Dictionary] = []

	# Categoria visual no Inspector
	properties.append({
		"name": "Input Sequence",
		"type": TYPE_NIL,
		"usage": PROPERTY_USAGE_CATEGORY
	})

	# Quantidade total de steps
	properties.append({
		"name": "total_inputs",
		"type": TYPE_INT,
	})

	# Propriedades dinâmicas por step
	for i in sequence_actions.size():
		properties.append({
			"name": "item_%d/input_actions" % i,
			"type": TYPE_INT,
			"hint": PROPERTY_HINT_FLAGS,
			"hint_string": ",".join(InputAction.keys())
		})
		properties.append({
			"name": "item_%d/duration" % i,
			"type": TYPE_FLOAT
		})

	return properties


func _get(property: StringName):
	if property == "total_inputs":
		return sequence_actions.size()

	if property.begins_with("item_"):
		var parts := property.trim_prefix("item_").split("/")
		var index := parts[0].to_int()
		if index >= sequence_actions.size():
			return null

		match parts[1]:
			"input_actions":
				var flags := 0
				for action_name in sequence_actions[index].split(","):
					action_name = action_name.strip_edges()
					if action_name in InputAction.keys():
						flags |= (1 << InputAction[action_name])
				return flags

			"duration":
				return sequence_durations[index]

	return null


func _set(property: StringName, value: Variant) -> bool:
	if property == "total_inputs":
		sequence_actions.resize(value)
		sequence_durations.resize(value)

		for i in range(value):
			if typeof(sequence_actions[i]) != TYPE_STRING:
				sequence_actions[i] = ""
			if typeof(sequence_durations[i]) != TYPE_FLOAT:
				sequence_durations[i] = 0.0

		notify_property_list_changed()
		return true

	if property.begins_with("item_"):
		var parts := property.trim_prefix("item_").split("/")
		var index := parts[0].to_int()
		if index >= sequence_actions.size():
			return false

		match parts[1]:
			"input_actions":
				var selected := []
				for i in InputAction.keys().size():
					if value & (1 << i):
						selected.append(InputAction.keys()[i])
				sequence_actions[index] = ",".join(selected)
				return true

			"duration":
				sequence_durations[index] = float(value)
				return true

	return false
