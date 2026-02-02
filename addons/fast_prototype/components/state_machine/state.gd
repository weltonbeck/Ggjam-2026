@icon("res://addons/fast_prototype/assets/icons/state.svg")
extends Node
class_name State

# ======================================================================
# State
# ----------------------------------------------------------------------
# Classe base para todos os estados utilizados pela StateMachine.
#
# Um estado representa um comportamento isolado, com callbacks para:
#   • Entrada e saída
#   • Atualização por frame
#   • Atualização de física
#   • Avaliação de transições automáticas
#
# Estados concretos devem herdar desta classe e sobrescrever apenas os
# métodos necessários. Esta classe nunca deve ser usada diretamente.
#
# Regras importantes:
#   • O nó pai DEVE ser uma StateMachine; caso contrário um erro é emitido.
#   • Cada estado deve possuir um nome único na cena.
#   • O método transition_to() permite que o estado solicite a troca.
# ======================================================================


# ======================================================================
# VARIÁVEIS
# ======================================================================


@export var active: bool = true

@export_group("Animation")

@export_subgroup("Animation Tree")
@export var animation_tree:AnimationTree
@export var animation_tree_animation_name:String
@export var animation_tree_blend_param: String

@export_subgroup("Animated Sprite")
@export var animated_sprite:AnimatedSprite2D
@export var animated_sprite_animation_name:String


@export_group("Audio")
@export var audio_stream_player:AudioStreamPlayer

## Referência interna para a StateMachine que gerencia este estado.
## É automaticamente definida pela própria StateMachine ao iniciar.
var state_machine: StateMachine = null

## Referência o comportamente do alvo
## É automaticamente definida pela própria StateMachine ao iniciar.
var behavior: CharacterBehavior = null


# ======================================================================
# SINAIS
# ======================================================================

## Emitido quando o estado é ativado. Envia o nome do estado anterior.
signal state_enter(last_state_name: String)

## Emitido quando o estado é desativado.
signal state_exit


# ======================================================================
# LIFECYCLE
# ======================================================================

func _ready() -> void:
	## Garante que este nó está corretamente ligado a uma StateMachine.
	if not get_parent() is StateMachine:
		push_error("State: Parent deve ser uma StateMachine.")
		return


func _state_name() -> String:
	## Retorna o nome do estado. Usado como chave interna.
	return get_name().to_lower()



# ======================================================================
# CALLBACKS DE CICLO DE VIDA DO ESTADO
# ======================================================================

func _on_state_ready() -> void:
	## Chamado quando o estado é registrado pela StateMachine.
	## Ideal para inicialização leve ou cache de nós.
	pass


func _on_state_process(_delta: float) -> void:
	## Chamado a cada frame. Usado para lógica não física.
	## Sobrescrever em estados concretos.
	pass


func _on_state_physics_process(_delta: float) -> void:
	## Chamado a cada frame de física. Usado para movimentação,
	## detecção de colisões e lógica dependente do time-step fixo.
	pass


func _on_state_next_transitions() -> void:
	## Permite ao estado atual solicitar diretamente sua transição,
	## por exemplo:
	##     if health <= 0:
	##         transition_to("dead")
	##
	## Chamado somente no estado atual.
	pass


func _on_state_check_transitions(_current_state_name: String, _current_state: Node) -> void:
	## Permite que outros estados monitorem o estado atual e
	## eventualmente forcem uma transição.
	##
	## Exemplo: um estado "hurt" pode ser disparado enquanto o
	## personagem está em "run".
	pass


func _on_state_enter(_last_state_name: String) -> void:
	## Chamado quando este estado se torna ativo.
	## Recebe o nome do último estado.
	##
	## Ideal para resetar variáveis, tocar animações, configurar timers etc.
	pass


func _on_state_exit() -> void:
	## Chamado antes de sair do estado ativo.
	## Ideal para limpar efeitos temporários, parar animações ou sons.
	pass


func _can_enter(_previous_state_name: String, _previous_state: State, _force:bool = false) -> Dictionary:
	## Determina se este estado pode ser ativado a partir de outro.
	##
	## Retorno padrão:
	##     { "allowed": true, "redirect": "" }
	##
	## Estados concretos podem sobrescrever e retornar:
	##     { "allowed": false, "redirect": "" }     # apenas bloqueia
	##     { "allowed": false, "redirect": "idle" } # envia para outro estado
	##
	return {
		"allowed": true,
		"redirect": ""   # se não puder entrar, qual state deve ser ativado no lugar
	}

# ======================================================================
# TRANSIÇÃO
# ======================================================================
func transition_to(state_name: String, force:bool = false) -> void:
	## Solicita troca de estado através da máquina.
	## Estado não deve fazer transição direta — sempre pedir via StateMachine.
	if state_machine:
		state_machine.transition_to(state_name, force)

func transition_to_me(force:bool = false) -> void:
	transition_to(_state_name(), force)

# ======================================================================
# AnimationTree UTILS
# ======================================================================

# Função chamada ao entrar neste estado
func _on_animation_play(_last_state_name:String) -> void:
	animation_tree_travel(animation_tree, animation_tree_animation_name)
	animated_sprite_travel(animated_sprite, animated_sprite_animation_name)
	
	
func _on_animation_process(_delta: float) -> void:
	if behavior:
		set_animation_tree_blend_param(animation_tree, animation_tree_blend_param,behavior._last_horizontal_input, behavior.get_last_input())
		
func set_animation_tree_blend_param(_animation_tree:AnimationTree, _param:String, _blend_1d_value: float = 0,_blend_2d_value:Vector2 = Vector2.ZERO):
	if not _animation_tree or not is_instance_valid(_animation_tree) or not _animation_tree.is_inside_tree() or not _param:
		return
		
	# Pega a lista completa de propriedades do AnimationTree
	var props = _animation_tree.get_property_list()

	var found_type: int = -1

	for p in props:
		if p.name == _param:
			found_type = p.type
			break

	if found_type == -1:
		# Propriedade não existe
		return
	
	# Define o valor de acordo com o tipo real da propriedade
	match found_type:
		TYPE_FLOAT:
			if abs(_blend_1d_value) > 0:
				_animation_tree.set(_param, _blend_1d_value)
		
		TYPE_VECTOR2:
			_animation_tree.set(_param, _blend_2d_value)


# Verifica a existência do estado e realiza o travel.
func animation_tree_travel(_animation_tree:AnimationTree, _animation_name: String, _playback_path: String = "parameters/playback") -> void:
	if  not _animation_tree or not is_instance_valid(_animation_tree) or not _animation_tree.is_inside_tree() or not _animation_name or not _playback_path or  not _animation_tree.get(_playback_path): 
		return
		
	
	var state_machine: AnimationNodeStateMachine = _animation_tree.tree_root
	var playback_control  = _animation_tree.get(_playback_path)
	var current_animation = playback_control .get_current_node()
	
	# Se já estiver na animação → restart
	if current_animation == _animation_name:
		return
		
	if state_machine.has_transition(current_animation, _animation_name):
		# Acessa o parâmetro usando a sintaxe de ponto e chama travel().
		playback_control.travel(_animation_name)

#animation sprite travel
func animated_sprite_travel(_animated_sprite:AnimatedSprite2D, _animation_name: String) -> void:
	if not _animated_sprite or not is_instance_valid(_animated_sprite) or not _animation_name or not _animated_sprite.sprite_frames.has_animation(_animation_name):
		return
	
	# Se já estiver tocando essa animação, sai fora
	if _animated_sprite.animation == _animation_name and _animated_sprite.is_playing():
		return
	
	_animated_sprite.play(_animation_name)

# Função chamada ao entrar neste estado
func _on_audio_play(_last_state_name:String) -> void:
	if audio_stream_player:
		audio_stream_player.play()


# ativa e desativa 

func activate() -> void:
	active = true
	
func deactivate() -> void:
	active = false
