## ===========================================================
## PlatformerCamera2D.gd — Câmera com comportamento estilo metroidvania
## ===========================================================
## Herda de BaseCamera2D (que já possui shake, zoom e transição)
## Faz o acompanhamento horizontal e vertical do personagem
## com zona morta e delay configuráveis.
## ===========================================================

class_name PlatformerCamera2D
extends BaseCamera2D

## =======================
## 🔧 Variáveis Exportadas
## =======================

@export var target: Node2D ## Objeto a ser seguido pela câmera.

@export var sub_viewport_container: SubViewportContainer 

# --- Movimento horizontal ---
@export_group("horizontal Moviment")

@export_range(0.1, 0.9) var line_x_ratio_to_left: float = 0.2 ## Posição horizontal da linha de referência no viewport. 
## Exemplo: 0.2 = 20% da largura da tela a partir da esquerda.

@export var approach_speed: float = 80.0 ## Velocidade de aproximação da câmera ao personagem 
## quando ele ultrapassa a linha de referência.

# --- Movimento vertical ---
@export_group("vertical Moviment")
@export_range(0.1, 0.9) var line_y_ratio_ground: float = 0.2 ## Linha base (mais baixa) da zona morta vertical, em proporção da tela.

@export var vertical_deadzone_height: float = 60.0 ## Altura total (em pixels) da zona morta vertical.

@export var vertical_follow_up_speed: float = 5.0 ## Velocidades para subir 
@export var vertical_follow_down_speed: float = 12.0 ## Velocidades para descer (descida costuma ser mais rápida).

@export var min_vertical_move: float = 1.0 ## Movimento mínimo necessário para atualizar a posição vertical (filtragem de jitter).

@export var vertical_follow_delay: float = 0.5 ## Tempo (em segundos) que o personagem pode ficar fora da zona morta antes da câmera reagir.

@export var screen_edge_margin: float = 10.0 ## Distância até a borda da tela para forçar acompanhamento, 
## mesmo antes do delay terminar (evita o jogador sair da tela).

## =======================
## Variáveis Internas
## =======================
var _target_prev_x: float = 0.0
var _line_x_ratio: float = 0.0
var _camera_float_x: float = 0.0
var _camera_float_y: float = 0.0
var _moving_right: bool = true
var _vertical_timer: float = 0.0


## =======================
## Ciclo de Vida
## =======================
func _ready():
	super._ready()
	position_smoothing_enabled = false  # Desativa o smoothing interno da Camera2D
	_line_x_ratio = line_x_ratio_to_left
	
	if is_instance_valid(target):
		_centralize_in_target()
		_target_prev_x = target.global_position.x
	
	_camera_float_x = global_position.x
	_camera_float_y = global_position.y

func _physics_process(delta: float) -> void:
	if not is_instance_valid(target):
		return
		
	_horizontal_movement(delta)
	_vertical_movement(delta)
	

## =======================
## Centralização inicial
## =======================
func _centralize_in_target() -> void:
	# Coloca a câmera centralizada no target, respeitando as linhas de proporção.
	var screen_size = get_viewport_rect().size
	var line_screen_x = -screen_size.x / 2 + (screen_size.x * _line_x_ratio)
	var line_screen_y = screen_size.y / 2 - (screen_size.y * line_y_ratio_ground)

	global_position.x = target.global_position.x - line_screen_x
	global_position.y = target.global_position.y - line_screen_y


## =======================
## ↔️ Movimento Horizontal
## =======================
func _horizontal_movement(delta: float) -> void:
	var screen_size = get_viewport_rect().size
	var screen_x_half = screen_size.x * 0.5
	var target_x = target.global_position.x
	
	# Detecta direção do movimento
	if target_x > _target_prev_x:
		_moving_right = true
		_line_x_ratio = line_x_ratio_to_left
		queue_redraw()
	elif target_x < _target_prev_x:
		_moving_right = false
		_line_x_ratio = abs(1 - line_x_ratio_to_left)
		queue_redraw()
	
	# Calcula a posição da linha de referência em coordenadas do mundo
	var line_world_x = _camera_float_x - screen_x_half + (screen_size.x * _line_x_ratio)
	var diff = target_x - line_world_x
	var target_move = target_x - _target_prev_x
	var target_moving = abs(target_move) > 0.05
	_target_prev_x = target_x
	
	var desired_x = _camera_float_x + diff
	
	# Move a câmera somente se o personagem cruzar a linha
	if (_moving_right and diff > 0) or (!_moving_right and diff < 0):
		_camera_float_x += target_move
		if target_moving:
			_camera_float_x = move_toward(_camera_float_x, desired_x, approach_speed * delta)
	
	
	
	global_position.x = _camera_float_x
	if pixel_snap_enabled:
		global_position = _snap_vector(global_position)


## =======================
## ↕️ Movimento Vertical
## =======================
func _vertical_movement(delta: float) -> void:
	if !is_instance_valid(target):
		return

	var screen_size = get_viewport_rect().size
	var screen_y_half = screen_size.y * 0.5

	# limites da deadzone (em world, relativos a _camera_float_y)
	var bottom_line_y = _camera_float_y + screen_y_half - (screen_size.y * line_y_ratio_ground)
	var top_line_y = bottom_line_y - vertical_deadzone_height
	var target_y = target.global_position.y

	var diff_y := 0.0
	var outside_deadzone := false
	var force_move := false

	# Detecta se o player está fora da zona morta
	if target_y < top_line_y:
		diff_y = target_y - top_line_y
		outside_deadzone = true
	elif target_y > bottom_line_y:
		diff_y = target_y - bottom_line_y
		outside_deadzone = true

	# Detecta se está prestes a sair da tela (limites de segurança)
	var top_screen_limit = _camera_float_y - screen_y_half + screen_edge_margin
	var bottom_screen_limit = _camera_float_y + screen_y_half - screen_edge_margin
	if target_y < top_screen_limit or target_y > bottom_screen_limit:
		force_move = true

	# Delay de reação normal
	if outside_deadzone:
		_vertical_timer += delta
	else:
		_vertical_timer = 0.0

	# --- Se precisamos forçar a câmera para dentro da tela, corrija IMEDIATAMENTE ---
	if force_move:
		# Queremos garantir que o target fique dentro da margem (screen_edge_margin)
		# Calcula deslocamento necessário para que target fique exatamente no limite
		if target_y < top_screen_limit:
			var shift = target_y - top_screen_limit
			_camera_float_y += shift
		elif target_y > bottom_screen_limit:
			var shift = target_y - bottom_screen_limit
			_camera_float_y += shift

		# opcional: agora também podemos começar a "acompanhar" suavemente o restante da diferença
		# (se houver diff_y). Mas não aplicamos a rampa de entrada brusca aqui.
		if abs(diff_y) > min_vertical_move:
			var speed = vertical_follow_up_speed if diff_y < 0 else vertical_follow_down_speed
			_camera_float_y = lerp(_camera_float_y, _camera_float_y + diff_y, clamp(delta * speed, 0.0, 1.0))

	# --- comportamento normal (com delay + suavização) ---
	elif _vertical_timer >= vertical_follow_delay:
		# ramp_in é a rampa curta para evitar trancos na entrada (0->1 em 0.2s)
		var ramp_in := clamp((_vertical_timer - vertical_follow_delay) / 0.2, 0.0, 1.0)

		if abs(diff_y) > min_vertical_move:
			var speed = vertical_follow_up_speed if diff_y < 0 else vertical_follow_down_speed
			var effective_speed = speed
			# aplicamos a rampa multiplicando a quantidade de lerp para suavizar entrada
			var smooth_factor = clamp(delta * effective_speed * ramp_in, 0.0, 1.0)
			_camera_float_y = lerp(_camera_float_y, _camera_float_y + diff_y, smooth_factor)

	# aplica pixel snap
	global_position.y = _camera_float_y
	if pixel_snap_enabled:
		global_position = _snap_vector(global_position)
	


## =======================
## 🔲 Debug Draw
## =======================
func _draw():
	if not get_tree().is_debugging_collisions_hint() or not is_current():
		return
	
	var screen_size = get_viewport_rect().size
	var screen_x_half = screen_size.x * 0.5
	var screen_y_half = screen_size.y * 0.5
	
	# Linha de direção (azul)
	var line_screen_x = -screen_x_half + (screen_size.x * _line_x_ratio)
	draw_line(Vector2(line_screen_x, -screen_y_half), Vector2(line_screen_x, screen_size.y), Color.DODGER_BLUE, 2)
	
	# Linha do chão e zona morta (coral)
	var line_screen_y = screen_y_half - (screen_size.y * line_y_ratio_ground)
	draw_line(Vector2(-screen_x_half, line_screen_y), Vector2(screen_size.x, line_screen_y), Color.CORAL, 2)
	draw_rect(Rect2(-screen_x_half, line_screen_y - vertical_deadzone_height, screen_size.x, vertical_deadzone_height), Color(1, 0.5, 0.3, 0.5), true)
	
	# --- Áreas de margem de tela (azul translúcido) ---
	draw_rect(
		Rect2(-screen_x_half, -screen_y_half, screen_size.x, screen_edge_margin),
		Color( 0, 0, 0.803922, 0.5),
		true
	)
	draw_rect(
		Rect2(-screen_x_half, screen_y_half - screen_edge_margin, screen_size.x, screen_edge_margin),
		Color( 0, 0, 0.803922,0.5),
		true
	)
