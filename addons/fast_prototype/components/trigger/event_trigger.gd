@tool
@icon("res://addons/fast_prototype/assets/icons/trigger.svg")
extends Node2D
class_name event_trigger

# ======================================================================
# Trigger
# ----------------------------------------------------------------------
# Sistema genérico de disparo de eventos no jogo. Permite executar
# múltiplos métodos em diferentes nós-alvo ao receber um sinal externo.
#
# Recursos:
#  • Funciona com um NodeSignal como gatilho.
#  • Pode executar múltiplos alvos simultaneamente ou em sequência.
#  • Suporta delays entre execuções.
#  • Pode tocar um som ao ativar.
#  • Pode se auto-destruir quando ativado (trigger_once).
#  • Possui visualização no editor para facilitar level design.
#
# Usos comuns:
#  • Abrir portas, mover plataformas, ativar cutscenes.
#  • Sequências de ações sincronizadas (ex.: puzzles).
#  • Gatilhos de gameplay baseados em colisões ou eventos.
# ======================================================================


# ======================================================================
# CONFIGURAÇÃO PRINCIPAL
# ======================================================================

enum TYPES { MULTIPLE, SEQUENCE }

## Se true, o trigger será executado apenas uma vez e se destruirá após concluir.
@export var trigger_once: bool = true

## MODO MULTIPLE:
##     Todos os alvos são disparados de forma independente.
##
## MODO SEQUENCE:
##     Cada alvo é chamado um após o outro com intervalo entre eles.
@export var type: TYPES = TYPES.MULTIPLE

## Intervalo (em segundos) entre ativações dos alvos.
## Aplicado no MULTIPLE antes do disparo,
## e aplicado entre cada item no SEQUENCE.
@export var time_interval: float = 0.2



# ======================================================================
# SINAL QUE ATIVA O TRIGGER
# ======================================================================

@export_category("Trigger")
## Referência para o node + sinal que dispara o trigger.
@export var signal_trigger: NodeSignal = null



# ======================================================================
# ALVOS DO TRIGGER
# ======================================================================

@export_category("Targets")
## Lista de métodos que serão executados quando o trigger ativar.
## NodeMethod encapsula:
##     - Nó alvo
##     - Nome do método a ser executado
@export var targets: Array[NodeMethod] = []



# ======================================================================
# SOM OPCIONAL
# ======================================================================

@export_category("Sound")
## Som reproduzido no momento da ativação.
@export var trigger_sound: AudioStreamPlayer2D = null



# ======================================================================
# SINAL DO SCRIPT
# ======================================================================

## Emitido sempre que o trigger é ativado.
signal triggered



# ======================================================================
# LIFECYCLE
# ======================================================================

func _ready() -> void:
	# Conecta dinamicamente o sinal ao método interno, mas apenas em runtime.
	if not Engine.is_editor_hint():
		if signal_trigger:
			signal_trigger.connect_signal(self, _on_trigger_active)



# ======================================================================
# ATIVAÇÃO DO TRIGGER
# ======================================================================

func _on_trigger_active() -> void:
	triggered.emit()  # Sinal interno para outros sistemas escutarem.

	# MULTIPLE: atraso antes de executar tudo.
	if type == TYPES.MULTIPLE:
		if time_interval > 0:
			await get_tree().create_timer(time_interval, false).timeout

		if trigger_sound:
			trigger_sound.play()

	# SEQUENCE ou MULTIPLE executam os alvos a seguir.
	for target in targets:

		if type == TYPES.SEQUENCE:
			# SEQUENTIAL MODE: delay + audio antes de cada item
			if time_interval > 0:
				await get_tree().create_timer(time_interval,false).timeout

			if trigger_sound:
				trigger_sound.play()

		call_target_method(target)

	# Após concluir tudo, decide se deve remover o node.
	if trigger_once:
		if trigger_sound:
			# Garante que o som termina antes da remoção.
			await trigger_sound.finished




# ======================================================================
# EXECUÇÃO DOS MÉTODOS ALVOS
# ======================================================================

func call_target_method(target: NodeMethod) -> void:
	if target and target.target_method_node:
		# O NodeMethod já sabe como chamar o método designado.
		target.call_method(self)



# ======================================================================
# DRAWING E DEBUG VISUAL NO EDITOR
# ======================================================================

func _process(_delta: float) -> void:
	# Atualiza o desenho sempre no editor para visual feedback.
	if Engine.is_editor_hint():
		queue_redraw()


func _draw() -> void:
	if Engine.is_editor_hint():

		# ------------------------------
		# Desenhar ícone / ponto base
		# ------------------------------
		var size := Vector2(5, 5)
		var rect := Rect2((size / 2) * -1, size)
		draw_rect(rect, Color.DARK_ORCHID, true)

		# ------------------------------
		# Desenhar linha até o node do sinal
		# ------------------------------
		if signal_trigger and signal_trigger.target_signal_node:
			var t := get_node_or_null(signal_trigger.target_signal_node)
			if t and t is Node2D:
				draw_line(
					Vector2.ZERO,
					to_local(t.global_position),
					Color.DARK_ORCHID,
					0.5
				)

		# ------------------------------
		# Desenhar linhas até os alvos
		# ------------------------------
		var last_point := Vector2.ZERO

		for target in targets:
			if target and target.target_method_node:
				var t := get_node_or_null(target.target_method_node)

				if t and t is Node2D:
					var to := to_local(t.global_position)

					# linha de ligação
					draw_line(last_point, to, Color.CORAL, 0.5)

					# marcador do alvo
					draw_circle(to, 1, Color.CHOCOLATE, true)

					# Em SEQUENCE, a próxima linha parte do último alvo
					if type == TYPES.SEQUENCE:
						last_point = to
