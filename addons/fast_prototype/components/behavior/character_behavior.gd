@icon("res://addons/fast_prototype/assets/icons/character_behavior.svg")
extends CharacterBody2D
class_name CharacterBehavior

var active_inputs: bool = true

var _last_velocity: Vector2 = Vector2.ZERO

#region Movement variables
@export_group("Movement Params")
@export var max_speed: float = 60.0 ## Velocidade máxima de movimento do personagem (em pixels por segundo).
@export var acceleration: float = 500.0 ## Aceleração ao mover-se na mesma direção (em pixels por segundo ao quadrado).
@export var deceleration: float = 500.0 ## Desaceleração ao se mover na mesma direção e esta com velocidade maior (em pixels por segundo ao quadrado).
@export var friction: float = 800.0 ## Redução da velocidade quando não há input de movimento (em pixels por segundo ao quadrado).
@export var turn_speed: float = 1400.0 ## Aceleração ao mudar de direção (valor maior permite resposta mais rápida ao inverter movimento).

var _horizontal_input:float = 0 # Entrada de direção do movimento (-1,0,1)
var _last_horizontal_input:float = 1 # ultima direção dada
var _vertical_input:float = 0 # Entrada de direção do movimento (-1,0,1)
var _last_vertical_input:float = 0 # ultima direção dada
var _last_input: Vector2 = Vector2.ZERO

var _face_direction: Vector2 = Vector2.DOWN ## direçao que o personagem esta olhando

signal face_direction_changed(face_direction:Vector2)

#endregion


#region Dash Variables

@export_group("Dash Variables")
@export var max_dashes: int = 1 ## maximo de dashes
@export var dash_speed: float = 300 ## velocidade do dash
@export var dash_duration_time: float = 0.15 ## tempo total do dash
@export var dash_input_buffer_time: float = 0.1 ## tempo do input buffer
@export var dash_cooldown_time: float = 0.5  ## Tempo até o proximo dash

var current_dash:int = 0 ## numero de dashes atual
var dash_duration_timer:float = 0 ## contador de tempo do dash
var dash_input_buffer_timer:float = 0 ## contador de tempo do input buffer
var dash_cooldown_timer:float = 0 ## contador de tempo até proximo dash

var _input_dash:bool = false ## controle do input de dash

#endregion

#region Attack Variables
@export_group("Attack Params")
@export var attack_input_buffer_time: float = 0.15 ## Tempo (em segundos) que o input de attack é armazenado, aguardando condição para atacar.

var _input_attack:bool = false ## controle do input de ataque
var _input_attack_pressed:bool = false ## controle do input de ataque pressionado
var _attack_input_buffer_timer:float = 0 ## controla o timer do input buffer
#endregion

func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING

func _process(delta: float) -> void:
	if active_inputs:
		_process_inputs(delta)
	_process_dash(delta)
	_process_attack(delta)

func _physics_process(_delta: float) -> void:
	pass

func activate_inputs_control() -> void:
	active_inputs = true

func deactivate_inputs_control() -> void:
	active_inputs = false

func _process_inputs(_delta: float) -> void:
	pass

func do_move_and_slide() -> bool:
	_last_velocity = velocity
	return super.move_and_slide()

#region Movement
func set_facing(_input:Vector2) -> void:
	if _input != Vector2.ZERO and _face_direction != _input.normalized():
		_face_direction = _input.normalized()
		emit_signal("face_direction_changed", _face_direction)

func set_horizontal_input(_input:float) -> void:
	_horizontal_input = _input
	if _input != 0:
		_last_horizontal_input = _input
		_last_input = Vector2(_input, 0)
		
func set_vertical_input(_input:float) -> void:
	_vertical_input = _input
	if _input != 0:
		_last_vertical_input = _input
		_last_input = Vector2(0, _input)

func get_input_axis() -> Vector2:
	return Vector2(_horizontal_input,_vertical_input)

func set_input(_input:Vector2) -> void:
	set_horizontal_input(_input.x)
	set_vertical_input(_input.y)
	if _input != Vector2.ZERO:
		_last_input = _input

func get_input() -> Vector2:
	return Vector2(_horizontal_input,_vertical_input)

func get_last_input() -> Vector2:
	return _last_input

func is_able_to_move() -> bool:
	return _has_horizontal_input() or _has_vertical_input()

func is_able_to_stop() -> bool:
	return not _has_horizontal_input() and not _has_vertical_input()

func horizontal_movement(delta:float,  _input:float = _horizontal_input, _max_speed:float = max_speed, _acceleration:float = acceleration, _deceleration:float = deceleration, _friction:float = friction, _turn_speed:float = turn_speed) -> void:
	velocity.x = _get_axis_movement(velocity.x, delta, _input,  _max_speed, _acceleration, _deceleration, _friction, _turn_speed)

func vertical_movement(delta:float,  _input:float = _vertical_input, _max_speed:float = max_speed, _acceleration:float = acceleration, _deceleration:float = deceleration, _friction:float = friction, _turn_speed:float = turn_speed) -> void:
	velocity.y = _get_axis_movement(velocity.y, delta, _input, _max_speed, _acceleration, _deceleration, _friction, _turn_speed)

func _has_horizontal_input() -> bool:
	return _horizontal_input != 0

func _has_vertical_input() -> bool:
	return _vertical_input != 0

func _get_axis_movement(axis_velocity, delta:float,  _input:float, _max_speed:float = max_speed, _acceleration:float = acceleration, _deceleration:float = deceleration, _friction:float = friction, _turn_speed:float = turn_speed ) -> float:
		
	# Calcula a velocidade alvo: direção * velocidade
	var target_speed = _input * _max_speed
	if target_speed != 0:
		if axis_velocity != 0 and sign(axis_velocity) != sign(target_speed):
			axis_velocity = move_toward(axis_velocity, 0, _turn_speed * delta)
		else:
			if abs(axis_velocity) > abs(target_speed):
				# Se estamos mais rápidos que o alvo, usamos fricção para desacelerar
				axis_velocity = move_toward(axis_velocity, target_speed, _deceleration * delta)
			else:
				## Aceleramos até à velocidade desejada
				axis_velocity = move_toward(axis_velocity, target_speed, _acceleration * delta)
	else:
		# Se não há movimento desejado, aplicamos fricção para parar gradualmente
		axis_velocity = move_toward(axis_velocity, 0, _friction * delta)
		
	return axis_velocity

#endregion

#region Dash

func set_input_dash(_input:bool) -> void:
	_input_dash = _input

# Reseta o número de dashes usados# Reseta o número de dashes usados
func reset_dashes() -> void:
	current_dash = 0  # Volta o contador de dashes para 0

func is_able_to_dash() -> bool:
	return _input_dash and current_dash < max_dashes and dash_cooldown_timer <= 0

func is_able_to_stop_dash() -> bool:
	return dash_duration_timer < 0

func get_valid_directions() -> Array[Vector2]:
	var directions = [Vector2.ZERO]
	directions.append(Vector2.LEFT)
	directions.append(Vector2.RIGHT)
	directions.append(Vector2.UP)
	directions.append(Vector2.DOWN)
	return directions

# Função que retorna a melhor direção para o dash com base no input
func get_dash_best_direction(_direction:Vector2) -> Vector2:
	_direction = _direction.normalized()  # Normaliza o vetor para magnitude 1

	#caso não tenha direção
	if _direction == Vector2.ZERO:
		return Vector2.ZERO  # Se não há input, retorna zero

	# Lista de direções permitidas para dash (cardeais e diagonais)
	var directions = get_valid_directions()
	
	var best_dir = directions[0]  # Direção inicial como padrão
	var best_dot = -1.0  # Produto escalar inicial (mínimo possível)

	# Compara cada direção válida com o input para achar a mais próxima
	for d in directions:
		var dot = _direction.dot(d)  # Produto escalar: mede alinhamento entre vetores
		if dot > best_dot:
			best_dot = dot  # Atualiza valor mais alto
			best_dir = d  # Atualiza melhor direção encontrada
	
	return best_dir  # Retorna a direção mais alinhada com o input

func handle_dash(delta:float, _force_direction: Vector2 = Vector2.ZERO) -> void:
	if dash_input_buffer_timer > 0:
		dash_input_buffer_timer -= delta  # Reduz o tempo do buffer
		
		# Calcula melhor direção para dash
		var _direction = get_input_axis()
		var _dash_direction:Vector2 = get_dash_best_direction(_direction)
		
		if _force_direction != Vector2.ZERO:
			_dash_direction = _force_direction
		
		#caso o buffer tenha acabado e não tenha direção forço para onde o character esta olhando
		if dash_input_buffer_timer <= 0 and _dash_direction == Vector2.ZERO:
			_dash_direction = get_dash_best_direction(_last_input)
			
		# Só executa o dash se houver direção válida
		if _dash_direction != Vector2.ZERO:
			var dash_multiplier = 1
			velocity = _dash_direction * dash_speed * dash_multiplier # Aplica velocidade do dash
		
			dash_duration_timer = dash_duration_time  # Define duração do dash
			dash_input_buffer_timer = 0 # zera o buffer
			current_dash += 1  # Incrementa o número de dashes usados
	
	elif dash_duration_timer > 0:
		dash_duration_timer -= delta  # Reduz o tempo restante do dash
		
func do_dash() -> void:
	dash_input_buffer_timer = dash_input_buffer_time
	dash_duration_timer = 0

func do_dash_cooldown() -> void:
	dash_cooldown_timer = dash_cooldown_time  # Inicia o cooldown

func _process_dash(delta:float) -> void:
	## Se ainda estiver no cooldown após um dash anterior
	if dash_cooldown_timer > 0:
		dash_cooldown_timer -= delta  # Diminui o tempo restante do cooldown
	
	# caso pisar no chão reseta os dash
	reset_dashes()


#endregion

#region atack Functions
func is_able_to_attack() -> bool:
	return _attack_input_buffer_timer > 0

func set_attack_input(_input:bool = false) -> void:
	_input_attack = _input

func set_attack_input_pressed(_input:bool = false) -> void:
	_input_attack_pressed = _input

func _process_attack(delta:float) -> void:
	#caso tiver apertado
	if _input_attack:
		# Ativa o temporizador de attack buffer
		_attack_input_buffer_timer = attack_input_buffer_time
	
	# Atualiza buffer timer
	if _attack_input_buffer_timer > 0:
		_attack_input_buffer_timer -= delta

#endregion

#region raycast
func _get_collider_from_raycast(_ray: RayCast2D, group_name:String = "") -> Node2D:
	if _ray and _ray.is_colliding():
		var collider = _ray.get_collider()
		
		# Verifica se está colidindo com o chão
		if collider :
			if group_name and not collider.is_in_group(group_name):
				return null
				
			return collider
	return null
#endregion
