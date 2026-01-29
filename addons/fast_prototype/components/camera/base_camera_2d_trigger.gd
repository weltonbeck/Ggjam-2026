@icon("res://addons/fast_prototype/assets/icons/base_camera2d_trigger.svg")
extends Node2D
class_name BaseCamera2DTrigger


# ======================================================================
# BaseCamera2DTrigger
# ----------------------------------------------------------------------
# Componente responsável por acionar efeitos de câmera ao receber um
# sinal externo. Ele serve como um "gatilho" modular que ativa zoom,
# shake, foco ou transição para outra câmera.
#
# Esse recurso é útil para cutscenes, eventos de gameplay, diálogos,
# colisões, triggers de área, ou qualquer evento que deva manipular a
# câmera dinamicamente.
# ======================================================================

# ======================================================================
# CONFIGURAÇÃO PRINCIPAL DO TRIGGER
# ======================================================================

@export var signal_trigger: NodeSignal = null ## Sinal externo que, ao ser emitido, dispara o trigger.
@export var active: bool = true              ## Define se o trigger está habilitado.
@export var trigger_once: bool = false       ## Se true, o trigger só executa uma vez.
@export var delay: float = 0.0               ## Atraso opcional antes de executar os efeitos.

var _has_triggered: bool = false             ## Controle interno se já foi executado.

signal trigged                                ## Emitido quando o trigger conclui a execução.



# ======================================================================
# GRUPO: EFEITOS DE CAMERA
# Cada grupo ativa um tipo específico de manipulação visual.
# ======================================================================

# ------------------------------------------
# ZOOM
# ------------------------------------------
@export_category("Effects")
@export_group("Zoom")
@export var zoom_enabled: bool = false       ## Ativa o efeito de zoom da câmera.
@export var zoom_target: Vector2 = Vector2(1.5, 1.5)  ## Nível de zoom alvo.
@export var zoom_speed: float = 2            ## Velocidade da animação do zoom.

# ------------------------------------------
# SHAKE
# ------------------------------------------
@export_group("Shake")
@export var shake_enabled: bool = false      ## Ativa o shake da câmera.
@export var shake_duration: float = 0.4      ## Duração do shake.
@export var shake_strength: float = 6.0      ## Intensidade do shake.

# ------------------------------------------
# FOCUS
# ------------------------------------------
@export_group("Focus")
@export var focus_enabled: bool = false      ## Ativa foco em um ponto/objeto.
@export var focus_target: NodePath           ## Nó que será focado.
@export var focus_animation_duration: float = 1.5  ## Velocidade do foco.

# ------------------------------------------
# TRANSITION
# ------------------------------------------
@export_group("Transition")
@export var transition_enabled: bool = false ## Ativa transição para outra câmera.
@export var transition_camera: BaseCamera2D  ## Câmera alvo.
@export var transition_animation_duration: float = 1.0 ## Velocidade da transição.



# ======================================================================
# INICIALIZAÇÃO
# Conecta o trigger ao sinal configurado.
# ======================================================================
func _ready() -> void:
	if signal_trigger:
		# Conecta o trigger ao método responsável por ativar os efeitos.
		signal_trigger.connect_signal(self, _on_trigger_active)



# ======================================================================
# MÉTODO DE ENTRADA DO TRIGGER
# Chamado automaticamente quando o sinal configurado é disparado.
# ======================================================================
func _on_trigger_active() -> void:
	if not active:
		return
	
	# Permite atraso opcional antes de executar.
	if delay > 0:
		await get_tree().create_timer(delay, false).timeout
	
	# Executa apenas se:
	#  - trigger_once for false
	#  - OU trigger_once for true mas ainda não foi executado
	if not trigger_once or (trigger_once and not _has_triggered):
		_trigger_all()
	
	_has_triggered = true
	trigged.emit()



# ======================================================================
# EXECUTA OS EFEITOS CONFIGURADOS
# Chamado internamente quando o trigger é acionado.
# ======================================================================
func _trigger_all() -> void:

	# --------------------------
	# TRANSIÇÃO DE CÂMERA
	# --------------------------
	if transition_enabled:
		var cam := transition_camera
		if cam and is_instance_valid(cam):
			CameraManager.change_camera(cam, transition_animation_duration)

	# --------------------------
	# ZOOM
	# --------------------------
	if zoom_enabled:
		CameraManager.zoom(zoom_target, zoom_speed)

	# --------------------------
	# SHAKE
	# --------------------------
	if shake_enabled:
		CameraManager.shake(shake_duration, shake_strength)

	# --------------------------
	# FOCUS EM OBJETO
	# --------------------------
	if focus_enabled:
		var node := get_node_or_null(focus_target)
		if node:
			CameraManager.focus_on(node.global_position, focus_animation_duration)
