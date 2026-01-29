extends Node

# =====================================================================
# GameStateManager.gd
# ---------------------------------------------------------------------
# Sistema global responsável por armazenar todos os estados persistentes
# do jogo, de forma genérica e expansível.
#
# O estado é representado por um dicionário único contendo qualquer tipo
# de informação (bool, int, float, String, Array, Dictionary).
#
# Exemplos de uso:
#   set_state("boss.fase1.morto", true)
#   set_state("inventario.chave_azul", true)
#   set_state("porta.sala_2.aberta", false)
#   set_state("puzzle.agua_resolvido", true)
#   set_state("player.vida_max", 20)
#
# Sempre que um valor muda, o sinal state_changed é emitido.
# =====================================================================

# Dicionário que armazena todas as variáveis de estado do jogo.
var state: Dictionary = {
	"debug.test": true
}

# Emitido quando qualquer valor do estado muda.
signal state_changed(key: String, new_value)


# =====================================================================
# Métodos Principais (GET / SET / REMOVE)
# =====================================================================

# Retorna se a chave existe.
func has_state(key: String) -> bool:
	return key in state


# Retorna o valor de uma variável de estado.
func get_state(key: String, default = null):
	if key in state:
		return state[key]
	return default


# Cria ou atualiza um valor no estado.
func set_state(key: String, value) -> void:
	state[key] = value
	state_changed.emit(key, value)


# Remove uma chave do estado.
func remove_state(key: String) -> void:
	if key in state:
		state.erase(key)
		state_changed.emit(key, null)

# inclementa no valor
func increment_state(key: String, increment_value: int = 1):
	var value = 0
	if key in state:
		value = state[key]
		
	# Se já for número
	if typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT:
		value = value + increment_value
	# Se for string, tenta converter
	elif typeof(value) == TYPE_STRING:
		if value.is_valid_int():
			value = int(value) + increment_value
		elif value.is_valid_float():
			value = float(value) + increment_value
	
	set_state(key, value)

# decrementa no valor
func decrement_state(key: String, decrement_value: int = 1):
	var value = 0
	if key in state:
		value = state[key]
		
	# Se já for número
	if typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT:
		value = value - decrement_value
	# Se for string, tenta converter
	elif typeof(value) == TYPE_STRING:
		if value.is_valid_int():
			value = int(value) - decrement_value
		elif value.is_valid_float():
			value = float(value) - decrement_value
	
	set_state(key, value)

# Limpa completamente o estado.
func clear_all() -> void:
	state.clear()
	state_changed.emit("*", null)


# lista completamente o estado.
func load_all() -> Dictionary:
	return state

# =====================================================================
# Conveniência (booleans, toggles)
# =====================================================================

# Atalho para estados booleanos.
func set_flag(key: String, enabled: bool = true) -> void:
	set_state(key, enabled)

func get_flag(key: String) -> bool:
	return get_state(key, false)

func toggle_flag(key: String) -> bool:
	var new_value = not get_flag(key)
	set_state(key, new_value)
	return new_value


# =====================================================================
# Integração com SaveManager
# =====================================================================

# EXPORTA o estado para salvar
func serialize() -> Dictionary:
	return state.duplicate(true)

# IMPORTA o estado carregado
func deserialize(data: Dictionary) -> void:
	state = data.duplicate(true)
	# sinal genérico indicando que "muita coisa mudou"
	state_changed.emit("*", null)
