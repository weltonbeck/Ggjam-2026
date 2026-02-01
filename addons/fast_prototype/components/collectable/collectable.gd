@tool
extends Area2D
class_name Collectable


## Variáveis exportadas e configurações de áudio
@export var starts_enabled: bool = true:
	set = set_starts_enabled

@export_group("Game State")
@export_placeholder("collectables.key") var game_state_key: String = "" ## collectable.name

@export_group("Block Unpack")
@export var eject_position: Vector2 =  Vector2(0, -16)
@export var eject_time: float = 0.1
@export var auto_collect: bool = false

@export_group("Audio")
## Player de áudio opcional, executado no momento da coleta
@export var audio_stream_player: AudioStreamPlayer2D

## Flag interna que impede a coleta múltipla no mesmo frame
var _collected: bool = false

## Sinal emitido quando o coletável é coletado com sucesso.
## Pode ser usado por sistemas externos como inventário, HUD, etc.
signal collected(collectable: Collectable)


# Métodos de inicialização e configuração

## Função chamada quando o coletável entra na cena.
## Configura o comportamento do coletável e ativa a visibilidade e a detecção de colisão.
func _ready() -> void:
	if not Engine.is_editor_hint():  # Garante que a lógica só ocorra em tempo de execução, não no editor.
		# Adiciona este objeto ao grupo de coletáveis para facilitar buscas e interações globais
		# (por exemplo, para reset de fase, save/load, debug, etc.)
		add_to_group(Globals.GROUP_COLLECTABLE)

		# Configura as camadas e máscaras de colisão do coletável
		set_collision_layers()
		
		# Define se o coletável deve começar habilitado ou não
		set_enabled(starts_enabled)


# Métodos de configuração de colisão

## Configura as camadas de colisão para garantir que este coletável
## apenas detecte sobreposição com entidades específicas, como o coletor.
func set_collision_layers() -> void:
	# Remove qualquer configuração padrão de colisão herdada
	collision_layer = 0
	collision_mask = 0

	# Ativa a camada de colisão específica para coletáveis
	set_collision_layer_value(Globals.LAYER_COLLECTABLE, true)


# Métodos para controle de ativação/desativação

## Define o estado inicial de visibilidade e interação no editor.
## No editor, ajusta a transparência (modulação) com base na flag `starts_enabled`.
func set_starts_enabled(_starts_enabled: bool) -> void:
	starts_enabled = _starts_enabled
	
	if Engine.is_editor_hint() and not _starts_enabled:
		modulate.a = 0.2  # Semi-transparente quando começa desativado
	else:
		modulate.a = 1  # Totalmente visível quando começa ativo


## Método utilizado para ativar ou desativar o coletável em tempo de execução.
## Controla a visibilidade, detecção e interação do coletável.
func set_enabled(enabled: bool) -> void:
	starts_enabled = enabled
	# Usando set_deferred para evitar conflitos com o ciclo de física
	# e garantir que as mudanças ocorram após a execução da lógica de física
	set_deferred("monitoring", enabled)
	set_deferred("monitorable", enabled)
	set_deferred("visible", enabled)


## Funções para ativar e desativar o coletável de maneira explícita

## Ativa o coletável, permitindo sua detecção e interação.
func enable() -> void:
	set_enabled(true)

## Desativa o coletável, ocultando-o e impedindo sua interação.
func disable() -> void:
	set_enabled(false)


# Método principal de coleta

## Este método é chamado por sistemas externos (por exemplo, Collector) quando o coletável é coletado.
## Emite um sinal para que sistemas como HUD ou inventário possam reagir.
func collect() -> void:
	# Verifica se o coletável já foi coletado para evitar coleta duplicada
	if _collected or not starts_enabled:
		return
		
	_collected = true

	# Emite o sinal de coleta para sistemas externos
	collected.emit(self)
	
	# caso tenha o game_state_key
	if game_state_key:
		GameStateManager.increment_state(game_state_key, 1)

	# Desativa o coletável (oculta e impede interação imediata)
	set_enabled(false)

	# Reproduz o áudio da coleta, se definido, e aguarda sua finalização
	if audio_stream_player:
		audio_stream_player.play()
		await audio_stream_player.finished

	# Aguarda um frame para garantir que sinais sejam processados corretamente
	# e sistemas externos tenham tempo para reagir antes da remoção do coletável
	await get_tree().process_frame

	# Remove o coletável da cena após o processamento do frame
	queue_free()

func block_unpack(target_position:Vector2,_direction: Vector2 = Vector2.UP) -> void:
	# posição inicial (saindo do bloco)
	global_position = target_position

	# cria tween
	var tween := create_tween()
	tween.tween_property(
		self,
		"global_position",
		target_position + eject_position,
		eject_time
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	await tween.finished
	if auto_collect:
		collect()
