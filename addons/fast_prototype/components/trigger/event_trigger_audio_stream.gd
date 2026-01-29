@icon("res://addons/fast_prototype/assets/icons/trigger.svg")
extends AudioStreamPlayer2D

@export_category("Signal Trigger")

## Se true, o trigger será executado apenas uma vez
## e será destruído após a ativação.
@export var trigger_once: bool = false

## Caminho do nó que emite o sinal que irá ativar este trigger.
@export var target_signal_node: NodePath

## Nome do sinal que será escutado no nó alvo.
@export var target_signal: String


## Sinal emitido sempre que o trigger é ativado.
## Pode ser usado por outros sistemas (ex: VFX, som, lógica extra).
signal triggered


func _ready() -> void:
	# Conecta o sinal externo ao método interno de ativação.
	_connect_target_signal(_on_trigger_active)


## Conecta dinamicamente um sinal externo a um callback local.
## O callback será executado sempre que o sinal alvo for emitido.
func _connect_target_signal(callback: Callable) -> void:
	if target_signal_node and target_signal:
		var signal_node := get_node_or_null(target_signal_node)

		# Garante que o nó existe e ainda é válido na cena.
		if signal_node and is_instance_valid(signal_node):
			# Wrapper para ignorar argumentos do sinal externo
			# e manter uma assinatura consistente.
			var wrapper := func(_args = []):
				callback.call()
			if not signal_node.is_connected(target_signal, Callable(wrapper)):
				signal_node.connect(target_signal, Callable(wrapper))


## Executado quando o sinal monitorado é disparado.
func _on_trigger_active() -> void:
	# Emite o sinal interno para outros sistemas escutarem.
	triggered.emit()

	play()

	# Se configurado como uso único, remove o trigger da cena.
	if trigger_once:
		call_deferred("queue_free")
