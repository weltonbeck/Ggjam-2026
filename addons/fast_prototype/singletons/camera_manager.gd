# ================================================================
# CameraManager.gd (versão estática)
# ---------------------------------------------------------------
# Sistema global de gerenciamento de câmeras, mas 100% estático.
# Não precisa de AutoLoad, basta importar o script e chamar direto:
#
#     CameraManager.change_camera(camera, 1.0)
#     CameraManager.shake(0.5, 8)
# ================================================================

class_name CameraManager

# --------------------------
# VARIÁVEIS ESTÁTICAS
# --------------------------

static var _enabled: bool = true
# Se false → ignora qualquer mudança de câmera (usado durante troca de cena)

static var _current_camera: BaseCamera2D = null
# Referência da câmera atualmente ativa (com current = true)

static var _previous_camera: BaseCamera2D = null
# Guarda a última câmera usada (para revert_to_previous)

static var _transition_in_progress: bool = false
# Indica se uma transição está rolando

static var _temp_camera: BaseCamera2D = null
# camera temporaria de transição

static var _transition_queue: Array = [] 
# fila de (camera, duration)

# ================================================================
#  CONTROLE DE ATIVAÇÃO
# ================================================================

static func enable():
	_enabled = true

static func disable():
	_enabled = false


# ================================================================
#  FUNÇÕES PRINCIPAIS
# ================================================================


## Registra a câmera (geralmente chamada no _ready() da câmera)
static func register_camera(camera: BaseCamera2D, make_current: bool = false) -> void:
	if camera == null:
		return

	if make_current:
		set_current_camera(camera)

## Define a câmera atual imediatamente (sem transição)
static func set_current_camera(camera: BaseCamera2D) -> void:
	if camera == null or camera == _current_camera:
		return

	_previous_camera = _current_camera

	_current_camera = camera
	_current_camera.make_current()


## Retorna a câmera atual
static func get_current_camera() -> BaseCamera2D:
	if _current_camera and is_instance_valid(_current_camera) and _current_camera.is_current():
		return _current_camera
	
	# Caso não esteja definida, procura a câmera current na cena
	var current_cam = _find_current_camera()
	if current_cam:
		set_current_camera(current_cam)
	return _current_camera

static func _find_current_camera() -> BaseCamera2D:
	var scene_tree = Engine.get_main_loop()
	if scene_tree is SceneTree:
		for cam in scene_tree.get_nodes_in_group(Globals.GROUP_CAMERA):
			if cam is BaseCamera2D and cam.current:
				return cam
	return null

## Retorna a câmera anterior
static func get_previous_camera() -> BaseCamera2D:
	if _previous_camera and is_instance_valid(_previous_camera):
		return _previous_camera
	return null

## Faz uma transição suave para outra câmera
static func change_camera(new_camera: BaseCamera2D, duration: float = 1.0) -> void:
	if not _enabled:
		return
	
	if new_camera == null or not is_instance_valid(new_camera):
		return

	# Impede duplicar a mesma câmera destino que já está na fila ou na transição atual
	if _transition_in_progress:
		if not _transition_queue.is_empty() and _transition_queue.back()["camera"] == new_camera:
			return  # já tá na fila, evita duplicar

		# Interrompe a transição atual e agenda a nova imediatamente
		_transition_queue.clear()
		_transition_queue.append({"camera": new_camera, "duration": duration})
		return

	# Se for exatamente a mesma câmera atual e não está em transição, nada a fazer
	if new_camera == _current_camera:
		return

	var current = get_current_camera()
	if current == null:
		set_current_camera(new_camera)
		return

	_transition_in_progress = true

	# === Cria câmera temporária ===
	var temp_cam := BaseCamera2D.new()
	var parent := current.get_parent()
	parent.add_child(temp_cam)
	temp_cam.global_position = current.global_position
	temp_cam.zoom = current.zoom
	temp_cam.rotation = current.rotation
	temp_cam.make_current()

	# === Pede pra ela fazer o blend ===
	temp_cam.connect("transition_ended", Callable(CameraManager, "_on_temp_camera_match_done").bind(temp_cam, new_camera), CONNECT_ONE_SHOT)
	temp_cam.transition_to_camera(new_camera, duration)

# método pra limpar fila manualmente
static func clear_transition_queue() -> void:
	_transition_queue.clear()

## Reverte para a câmera anterior
static func revert_to_previous(duration: float = 1.0) -> void:
	if not _enabled:
		return
		
	if _previous_camera and is_instance_valid(_previous_camera):
		change_camera(_previous_camera, duration)


# ================================================================
#  EFEITOS REUTILIZÁVEIS (repasse para a câmera atual)
# ================================================================

## Tremor (shake)
static func shake(duration: float, strength: float = 8.0) -> void:
	if not _enabled:
		return
		
	var camera = get_current_camera()
	if camera:
		camera.start_shake(duration, strength)

## Zoom dinâmico
static func zoom(target_zoom: Vector2, speed: float = 3.0) -> void:
	if not _enabled:
		return
		
	var camera = get_current_camera()
	if camera:
		camera.start_zoom(target_zoom, speed)

## Reset do zoom
static func reset_zoom(speed: float = 3.0) -> void:
	if not _enabled:
		return
		
	var camera = get_current_camera()
	if camera:
		camera.reset_zoom(speed)

## Foco em ponto (focus shift)
static func focus_on(point: Vector2, duration: float = 1.0) -> void:
	if not _enabled:
		return
		
	var camera = get_current_camera()
	if camera:
		camera.focus_on_point(point, duration)


# ================================================================
#  CALLBACK INTERNO
# ================================================================

static func _on_temp_camera_match_done(temp_cam: BaseCamera2D, target_camera: BaseCamera2D) -> void:
	if temp_cam:
		temp_cam.queue_free()

	if target_camera:
		set_current_camera(target_camera)

	_transition_in_progress = false

	# Se tiver mais na fila, começa a próxima
	if not _transition_queue.is_empty():
		var next = _transition_queue.pop_front()
		change_camera(next["camera"], next["duration"])
