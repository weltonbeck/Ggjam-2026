@icon("res://addons/fast_prototype/assets/icons/state_machine.svg")
extends Node
class_name StateMachine


# ======================================================================
# StateMachine
# ----------------------------------------------------------------------
# Implementação de uma máquina de estados genérica baseada em nós filhos.
# Cada estado deve estender a classe "State" e ser inserido como filho
# direto deste nó. A máquina gerencia:
#
#  • Entrada e saída de estados
#  • Chamadas de update e physics
#  • Transições automáticas e manuais
#  • Sinalização de mudanças de estado
#
# Uso típico:
#  • IA de inimigos
#  • Controle de personagem
#  • Sistemas de interação complexos
#
# Requisitos:
#  • Cada filho que represente um estado deve:
#       - herdar de `State`
#       - implementar métodos _on_state_enter, _on_state_exit, etc.
#       - definir um nome único via _state_name()
# ======================================================================


# ======================================================================
# CONFIGURAÇÃO
# ======================================================================

@export var behavior: CharacterBehavior
## Referência opcional usada pelos estados (por exemplo, o personagem que
## esta StateMachine controla).


@export var initial_state: State
## Estado inicial a ser ativado quando a cena começar. Deve ser um nó filho
## deste StateMachine.


# ======================================================================
# VARIÁVEIS INTERNAS
# ======================================================================

var node_states: Dictionary = {}
## Dicionário: { nome_do_estado (lowercase) : State }
## Facilita lookup rápido por nome.

var current_state: State = null
## Referência ao estado atualmente ativo.

var current_state_name: String = ""
## Nome do estado ativo (lowercase).

var last_state_name: String = ""
## Nome do estado anterior ao atual; usado em callbacks de entrada/saída.


signal state_changed(state_name: String)
## Emitido sempre que ocorre uma troca de estado.



# ======================================================================
# LIFECYCLE
# ======================================================================

func _ready() -> void:
	# Em modo editor, a StateMachine não deve rodar lógica de runtime.
	if not Engine.is_editor_hint():

		# --------------------------------------------------------------
		# Varre os filhos e coleta todos os estados
		# --------------------------------------------------------------
		for child in get_children():

			if child is State:
				var key:String = child._state_name().to_lower()

				# Registra o estado no dicionário
				node_states[key] = child

				# Estabelece link para esta máquina
				child.state_machine = self
				if behavior:
					child.behavior = behavior

				# Callback opcional executado pelo estado
				child._on_state_ready()


		# --------------------------------------------------------------
		# Inicializa o estado inicial (se definido)
		# --------------------------------------------------------------
		if initial_state:
			initial_state._on_state_enter(last_state_name)
			current_state = initial_state
			current_state_name = initial_state._state_name().to_lower()



# ======================================================================
# PROCESSAMENTO POR FRAME
# ======================================================================

func _process(delta: float) -> void:
	# Em runtime delega ao estado atual o update lógico.
	if not Engine.is_editor_hint() and current_state:
		current_state._on_state_process(delta)



# ======================================================================
# PROCESSAMENTO DE FÍSICA
# ======================================================================

func _physics_process(delta: float) -> void:
	if not Engine.is_editor_hint() and current_state:

		# Chamado em todo frame de física
		current_state._on_state_physics_process(delta)

		# Permite que o estado atual solicite transições
		current_state._on_state_next_transitions()

		# Verifica condições externas em todos os estados
		for key in node_states:
			node_states[key]._on_animation_process(delta)
			if node_states[key].active:
				node_states[key]._on_state_check_transitions(
					current_state._state_name(),
					current_state
				)



# ======================================================================
# TRANSIÇÃO ENTRE ESTADOS
# ======================================================================

func transition_to(state_name: String, force:bool = false) -> void:
	## Solicita a troca para um estado pelo nome (case-insensitive).

	var target_name := state_name.to_lower()

	# Evita transição redundante
	if not force and target_name == current_state._state_name().to_lower():
		return

	# Busca no dicionário de estados
	var new_state: State = node_states.get(target_name)

	# Estado inexistente → aborta
	if not new_state:
		return
	
	# verifica se pode mudar
	var enter_info := new_state._can_enter(current_state_name, current_state, force)
	var allowed: bool = enter_info.get("allowed", true)
	var redirect: String = enter_info.get("redirect", "")
	if not allowed:
		if redirect != "":
			transition_to(redirect)
		return

	# --------------------------------------------------------------
	# Sair do estado atual
	# --------------------------------------------------------------
	if current_state:
		current_state._on_state_exit()
		current_state.state_exit.emit()
		last_state_name = current_state_name

	# --------------------------------------------------------------
	# Entrar no novo estado
	# --------------------------------------------------------------
	new_state._on_state_enter(last_state_name)
	new_state.state_enter.emit(last_state_name)
	new_state._on_animation_play(last_state_name)
	new_state._on_audio_play(last_state_name)

	state_changed.emit(state_name)


	# --------------------------------------------------------------
	# Atualiza estado ativo
	# --------------------------------------------------------------
	current_state = new_state
	current_state_name = new_state._state_name().to_lower()
	
	print("Current State: ", current_state_name,", Behavior: ", behavior)  # Debug opcional

# ======================================================================
# Verifica se tem o state
# ======================================================================

func has_state(state_name:String) -> bool:
	if node_states.has(state_name.to_lower()):
		var new_state: State = node_states.get(state_name.to_lower())
		if new_state.active:
			return true
	return false
