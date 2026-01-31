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
	if not target_signal_node or not target_signal:
		return

	var signal_node := get_node_or_null(target_signal_node)
	if not signal_node or not is_instance_valid(signal_node):
		return

	# Descobre quantos argumentos o signal possui
	var arg_count := 0
	for s in signal_node.get_signal_list():
		if s.name == target_signal:
			arg_count = s.args.size()
			break

	var safe_callable: Callable

	if arg_count > 0:
		# Ignora TODOS os argumentos
		safe_callable = callback.unbind(arg_count)
	else:
		# Signal sem argumentos → não faz unbind
		safe_callable = callback

	if not signal_node.is_connected(target_signal, safe_callable):
		signal_node.connect(target_signal, safe_callable)

## Executado quando o sinal monitorado é disparado.
func _on_trigger_active() -> void:
	# Emite o sinal interno para outros sistemas escutarem.
	triggered.emit()

	play()

	# Se configurado como uso único, remove o trigger da cena.
	if trigger_once:
		call_deferred("queue_free")
