class_name BaseCamera2D
extends Camera2D

## ==========================================================================================
##  BaseCamera2D.gd
## ------------------------------------------------------------------------------------------
##  Classe base para todas as câmeras do projeto.
##  Fornece funcionalidades essenciais, normalmente esperadas em engines AAA:
##
##   ✔ Screen Shake        – Tremor da câmera com decaimento controlado.
##   ✔ Dynamic Zoom        – Interpolação suave de zoom com snapping opcional.
##   ✔ Focus Shift         – Movimentação guiada da câmera até um ponto específico.
##   ✔ Camera Transition   – Transição completa entre duas câmeras (pos/rot/zoom).
##
##  Esta câmera NÃO implementa comportamentos de gameplay diretamente —
##  ela funciona como uma unidade de efeitos reutilizáveis para sistemas superiores.
##
##  Cada efeito expõe sinais de início e fim, permitindo que UI/SFX se sincronizem
##  com segurança com a engine de câmera.
##
## ==========================================================================================


# --------------------------
# SIGNALS (eventos públicos)
# --------------------------
# Emitem quando efeitos começam/terminam; úteis para sincronizar som/GUI/estado.
signal shake_started        ## Emitido no momento exato em que o tremor inicia.
signal shake_ended          ## Emitido quando o tremor termina e o offset é restaurado.
signal zoom_started         ## Emitido quando uma interpolação de zoom é iniciada.
signal zoom_ended           ## Emitido quando o zoom chega ao valor alvo.
signal focus_started        ## Emitido quando inicia o movimento de foco para um ponto.
signal focus_ended          ## Emitido quando a câmera atinge o ponto de foco.
signal transition_started   ## Emitido quando começa a transição para outra câmera.
signal transition_ended     ## Emitido ao completar a interpolação com a câmera alvo.
# --------------------------
# EXPORTED CONFIG VARIABLES
# --------------------------
# Valores exportados para ajustar no editor (tweak rápido sem tocar no código).

@export var is_current_camera: bool = false ## ativa ela como camera principal do jogo

@export_group("Base movement config")

@export var shake_decay: float = 5.0 ## Quando um shake está ativo, este valor controla a rapidez com que o efeito decai ao longo do tempo.
# Valores maiores: queda mais rápida do tremor.

@export var shake_strength: float = 8.0 ## Força padrão do shake (em pixels). Pode ser sobreposto ao iniciar um shake.

@export var transition_speed: float = 3.0 ## Velocidade padrão para transições; serve como referência (não usado diretamente no código,
# mas exportado para ajustes e possíveis extensões).

# --- Pixel-perfect snapping ---
@export_group("Pixel Snapping")
@export var pixel_snap_enabled: bool = true
@export var pixel_size: float = 1.0  # tamanho do pixel lógico (1.0 = 1px real)


# --------------------------
# INTERNAL STATE (não expostos)
# --------------------------
# Variáveis internas que guardam o estado atual de cada efeito.

# --- Shake state ---
var _shake_time: float = 0.0
var _shake_duration: float = 0.0
var _shake_power: float = 0.0
var _shake_active: bool = false

# --- Zoom state ---
var _default_zoom: Vector2 = Vector2.ONE ## Zoom padrão/restauração (1,1 é 100%). Usado em reset_zoom().
var _zoom_target: Vector2 = Vector2.ONE
var _zoom_speed: float = 0.0
var _zoom_active: bool = false

# --- Focus shift state ---
var _focus_target: Vector2 = Vector2.ZERO
var _focus_duration: float = 0.0
var _focus_timer: float = 0.0
var _focus_origin: Vector2 = Vector2.ZERO
var _focus_active: bool = false

# --- Camera transition state ---
var _transition_target: Camera2D = null
var _transition_timer: float = 0.0
var _transition_duration: float = 0.0
var _transition_active: bool = false
var _transition_origin_pos: Vector2 = Vector2.ZERO
var _transition_origin_zoom: Vector2 = Vector2.ONE
var _transition_origin_rot: float = 0.0


func _ready() -> void:
	_default_zoom = zoom
	add_to_group(Globals.GROUP_CAMERA, true)
	CameraManager.register_camera(self, is_current_camera or is_current())

# Atualiza todos os efeitos ativos. Usado no _process para rodar a lógica por frame.
func _physics_process(delta: float) -> void:
	# atualiza cada efeito separadamente (se estiver ativo)
	if _shake_active:
		_update_shake(delta)
	if _zoom_active:
		_update_zoom(delta)
	if _focus_active:
		_update_focus(delta)
	# Atualiza transição (se esta for uma câmera temporária)
	if _transition_active:
		_update_transition(delta)

# --------------------------
# SHAKE (screen shake)
# --------------------------
# API pública:
#   start_shake(duration: float, strength: float)
#   - duration: tempo em segundos que o shake vai durar
#   - strength: intensidade em pixels (opcional; usa shake_strength se omitido)
#
# Sinais:
#   shake_started, shake_ended
#
# Observações:
# - O shake escreve em `offset` (propriedade do Camera2D) para deslocar a câmera visualmente.
# - O efeito decai linearmente ao longo da duração (podes trocar por exponencial se quiseres).

func start_shake(duration: float, strength: float = shake_strength) -> void:
	# Inicia o shake com duração e força dadas.
	_shake_duration = max(duration, 0.0)
	_shake_time = 0.0
	_shake_power = strength
	_shake_active = true
	emit_signal("shake_started")

func _update_shake(delta: float) -> void:
	_shake_time += delta
	# Quando o tempo excede a duração, para o shake e reseta offset
	if _shake_time >= _shake_duration:
		offset = Vector2.ZERO
		_shake_active = false
		emit_signal("shake_ended")
		return

	# decay: quanto do shake ainda permanece (1 -> full, 0 -> none)
	var decay = 1.0 - (_shake_time / _shake_duration)
	# offset aleatório na faixa [-1,1] * poder * decay
	var random_offset = Vector2(
		randf_range(-1.0, 1.0),
		randf_range(-1.0, 1.0)
	) * _shake_power * decay
	
	if pixel_snap_enabled:
		random_offset = _snap_vector(random_offset)
	
	# Aplica deslocamento visual (não altera posição global da câmera)
	offset = random_offset

# --------------------------
# DYNAMIC ZOOM
# --------------------------
# API pública:
#   start_zoom(target_zoom: Vector2, speed: float = 3.0)
#   reset_zoom(speed: float = 3.0)
#
# Sinais:
#   zoom_started, zoom_ended
#
# Observações:
# - Faz interpolação suave entre o zoom atual e o zoom alvo.
# - Usa lerp no zoom (Vector2.lerp) e emite sinais quando termina.

func start_zoom(target_zoom: Vector2, speed: float = 3.0) -> void:
	_zoom_target = target_zoom
	_zoom_speed = max(speed, 0.01)
	_zoom_active = true
	emit_signal("zoom_started")

func reset_zoom(speed: float = 3.0) -> void:
	# Volta ao zoom padrão exportado
	start_zoom(_default_zoom, speed)

func _update_zoom(delta: float) -> void:
	# Interpola o zoom atual em direção ao alvo.
	zoom = zoom.lerp(_zoom_target, delta * _zoom_speed)
	
	# Quantiza o zoom para valores seguros
	zoom = _quantize_zoom(zoom)

	if zoom.distance_to(_zoom_target) < 0.001:
		zoom = _zoom_target
		_zoom_active = false
		emit_signal("zoom_ended")

func _quantize_zoom(z: Vector2) -> Vector2:
	if not pixel_snap_enabled:
		return z
	var step = 0.1  # quanto mais baixo, mais preciso
	return Vector2(
		round(z.x / step) * step,
		round(z.y / step) * step
	)

# --------------------------
# FOCUS SHIFT (mover até um ponto)
# --------------------------
# API pública:
#   focus_on_point(target_pos: Vector2, duration: float = 1.0)
#
# Sinais:
#   focus_started, focus_ended
#
# Observações:
# - Move a câmera (global_position) desde a origem até target_pos ao longo de duration segundos.
# - Útil para cutscenes, mostrar um objeto ou alvo temporariamente.

func focus_on_point(target_pos: Vector2, duration: float = 1.0) -> void:
	_focus_target = target_pos
	_focus_origin = global_position
	_focus_duration = max(duration, 0.01)
	_focus_timer = 0.0
	_focus_active = true
	emit_signal("focus_started")

func _update_focus(delta: float) -> void:
	_focus_timer += delta
	var t = clamp(_focus_timer / _focus_duration, 0.0, 1.0)
	# Interpola posição da câmera
	var pos = _focus_origin.lerp(_focus_target, t)

	if pixel_snap_enabled:
		pos = _snap_vector(pos)

	global_position = pos
	
	if t >= 1.0:
		_focus_active = false
		emit_signal("focus_ended")



# --------------------------
# TRANSIÇÃO PARA OUTRA CÂMERA
# --------------------------
# API pública:
#   transition_to_camera(target_camera: Camera2D, duration: float = 1.0)
#
# Sinais:
#   transition_started, transition_ended
#
# Observações:
# - Interpola posição, zoom e rotação entre esta câmera e target_camera durante duration segundos.

func transition_to_camera(target_camera: Camera2D, duration: float = 1.0) -> void:
	if target_camera == null:
		return
	_transition_target = target_camera
	_transition_origin_pos = global_position
	_transition_origin_zoom = zoom
	_transition_origin_rot = rotation
	_transition_duration = max(duration, 0.01)
	_transition_timer = 0.0
	_transition_active = true
	emit_signal("transition_started")

func _update_transition(delta: float) -> void:
	_transition_timer += delta
	var t = clamp(_transition_timer / _transition_duration, 0.0, 1.0)

	# Interpola posição/zoom/rotação
	var pos = _transition_origin_pos.lerp(_transition_target.global_position, t)
	var z = _transition_origin_zoom.lerp(_transition_target.zoom, t)
	var rot = lerp_angle(_transition_origin_rot, _transition_target.rotation, t)

	# --- Pixel-perfect snapping ---
	if pixel_snap_enabled:
		pos = _snap_vector(pos)
		z = _quantize_zoom(z)
		# rotação raramente é usada em pixel-art, mas deixamos arredondada em passos pequenos
		rot = round(rot * 1000.0) / 1000.0  # evita jitter visual

	global_position = pos
	zoom = z
	rotation = rot
	
	# Ao final, marca camera alvo como current e emite sinal
	if t >= 1.0:
		_transition_active = false
		emit_signal("transition_ended")

# --------------------------
# UTILS / HELPERS (extras)
# --------------------------
func is_shaking() -> bool:
	return _shake_active

func is_zooming() -> bool:
	return _zoom_active

func is_focusing() -> bool:
	return _focus_active

func is_transitioning() -> bool:
	return _transition_active

func _snap(value: float) -> float:
	return round(value / pixel_size) * pixel_size

func _snap_vector(v: Vector2) -> Vector2:
	return Vector2(
		round(v.x / pixel_size) * pixel_size,
		round(v.y / pixel_size) * pixel_size
	)
