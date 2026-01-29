@tool
@icon("res://addons/fast_prototype/assets/icons/music_trigger.svg")
extends Node
class_name MusicTrigger

# ============================================================================
#  CONFIGURAÇÕES PRINCIPAIS
# ----------------------------------------------------------------------------
# `music_stream` é a música associada a este trigger.
# Usa backing-field privado para evitar recursão no getter/setter.
# ============================================================================
var _music_stream: AudioStream = null

@export var music_stream: AudioStream:
	get:
		return _music_stream
	set(value):
		# Se o preview estiver tocando e o usuário remover a música
		# — interrompe automaticamente o preview
		if value == null and _editor_player and _editor_player.playing:
			_stop_preview()

		_music_stream = value


# Se ativado, toca a música automaticamente ao entrar na cena (runtime)
@export var play_on_ready: bool = true

# Se disponível, usa o AudioManager para crossfade
@export var use_fade: bool = true

@export_range(0,100) var music_volume: int = 100


# Player usado apenas em runtime quando AudioManager não está disponível
var _local_player: AudioStreamPlayer = null

# Player exclusivo do EDITOR (preview)
var _editor_player: AudioStreamPlayer = null



# ============================================================================
#  EDITOR PREVIEW
# ----------------------------------------------------------------------------
# Criamos um checkbox "Preview" no inspector.
# O estado do checkbox é vinculado ao estado real do player do editor.
# ============================================================================
@export_group("Preview")
@export var _preview_play: bool = false:
	get:
		# Reflete o estado real do player — não apenas a variável exportada
		if _editor_player:
			return _editor_player.playing
		return false

	set(value):
		# Ativar preview
		if value:
			_play_preview_logic()
		# Desativar preview
		else:
			_stop_preview()



# ============================================================================
#  INITIALIZATION
# ============================================================================
func _ready():
	# Não tocar preview automaticamente no editor
	if Engine.is_editor_hint():
		return

	# Em runtime, toca automaticamente se configurado
	if play_on_ready:
		activate()



# ============================================================================
#  PUBLIC API — ATIVA A MÚSICA NO JOGO
# ============================================================================
func activate():
	if _music_stream == null:
		push_warning("MusicTrigger: Nenhuma música definida.")
		return

	# Preferência: usar AudioManager (fade automático, crossfade etc)
	if AudioManager:
		AudioManager.play_bgm(_music_stream, use_fade, music_volume)
		return

	# Caso AudioManager não exista → tocar localmente
	_play_local()



# ============================================================================
#  RUNTIME LOCAL PLAYER (fallback)
# ============================================================================
func _play_local():
	if _local_player == null:
		_local_player = AudioStreamPlayer.new()
		_local_player.bus = "BGM"
		add_child(_local_player)

	_local_player.stream = _music_stream
	_local_player.volume_db = 0
	_local_player.play()



# ============================================================================
#  PARA MÚSICA EM RUNTIME
# ============================================================================
func stop():
	# Se houver AudioManager → usa ele
	if Engine.has_singleton("AudioManager"):
		var AM = Engine.get_singleton("AudioManager")
		if AM.has_method("stop_bgm"):
			AM.stop_bgm()
			return

	# Fallback local
	if _local_player:
		_local_player.stop()



# ============================================================================
#  EDITOR PREVIEW — PLAY
# ----------------------------------------------------------------------------
# Ativado quando o usuário marca o checkbox de preview.
# ============================================================================
func _play_preview_logic():
	if _music_stream == null:
		push_warning("MusicTrigger: Nenhuma música definida para preview.")
		_preview_play = false  # desfaz checkbox
		return

	# Cria player de preview se ainda não existir
	if _editor_player == null:
		_editor_player = AudioStreamPlayer.new()
		_editor_player.name = "__EDITOR_PREVIEW_PLAYER__"
		add_child(_editor_player)

	# Se não estiver tocando ainda → inicia preview
	if not _editor_player.playing:
		_editor_player.stream = _music_stream
		_editor_player.volume_db = 0
		_editor_player.play()



# ============================================================================
#  EDITOR PREVIEW — STOP
# ----------------------------------------------------------------------------
# Chamado quando o usuário desmarca o checkbox ou remove a música.
# ============================================================================
func _stop_preview():
	if _editor_player and _editor_player.playing:
		_editor_player.stop()
