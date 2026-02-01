extends CharacterBehavior
class_name CharacterPlaformerBehavior

#region air Variables
@export_group("Air Movement Params")
@export var air_max_speed: float = 80.0 ## Velocidade máxima de movimento horizontal do personagem no ar(em pixels por segundo).
@export var air_acceleration: float = 800.0 ## Aceleração ao mover-se na mesma direção no ar(em pixels por segundo ao quadrado).
@export var air_deceleration: float = 300.0 ## Desaceleração ao mover-se na mesma direção no ar(em pixels por segundo ao quadrado).
@export var air_friction: float = 500.0 ## Redução da velocidade quando não há input de movimento no ar(em pixels por segundo ao quadrado).
@export var air_turn_speed: float = 1400.0 ## Aceleração ao mudar de direção no ar (valor maior permite resposta mais rápida ao inverter movimento).
#endregion

#region slope Variables
@export_group("Slope Movement Params")
@export var use_slope_movement: bool = true ## ativa o uso de slope
@export_range(1,89) var min_slope_angle: float= 35.0  ## angulo minimo que começa a escorregar
@export_range(1,89) var max_slope_angle: float = 46.0 ## angulo maximo que pode escorregar
@export var slope_up_speed_mult: float = 0.6   ## multiplicador de velocidade ao subir rampa
@export var slope_down_speed_mult: float = 1.2  ## multiplicador de velocidade ao descer rampa
@export var slope_slide_force: float = 80  ## força que escorrega

#endregion

#region gravity Variables
@export_group("Gravity Params")
@export var gravity:float = 800 ##valor da gravidade
@export var max_gravity:float = 1200 ##valor maximo da gravidade
@export var hang_time_gravity_multiplier: float = 0.5 ## Multiplicador de gravidade no topo do pulo, para sensação de flutuação.
@export var fast_fall_gravity_multiplier: float = 1.3 ## Multiplicador de gravidade ao cair, acelera a queda.
@export var hang_time_threshold: float = 50.0 ## Limite de velocidade vertical para ativar o hang time (gravidade reduzida no topo).

var _through_platform_down_force = 2 # força de descida da plataforma

@export_subgroup("Fast fall")
@export var fast_fall_hold_time: float = 0.1 ## Tempo necessário segurando para ativar fast fall

var _fast_fall_timer: float = 0.0
var _fast_fall_input_pressed: bool = false
#endregion

#region Jump Variables
@export_group("Jump Params")
@export var jump_speed: float = 240 ## velocidade do pulo
@export var jump_cut_off_speed: float = 100 ## velocidade minima do pulo quando solta o botao
@export var jump_coyote_time: float = 0.08 ## Tempo (em segundos) após sair do chão em que ainda é possível pular (coyote time).
@export var jump_input_buffer_time: float = 0.15 ## Tempo (em segundos) que o input de pulo é armazenado, aguardando condição para pular.
@export var max_jumps: int = 1 ## Quantidade de pulos (pulo duplo ou mais).

var _current_jump:int = 0 ## numero do pulo atual
var _jump_input_buffer_timer:float = 0 ## controla o timer do input buffer
var _jump_coyote_timer:float = 0 ## controla o timer do coyote

var _input_jump:bool = false ## controle do input de pulo
var _input_jump_pressed:bool = false ## controle do input de  pulo pressionado

var _force_jump: bool = false ## caso esteja forçando o pulo
var _jump_multiply: float = 1 ## multiplicação do pulo para pular mais alto
var _in_force_jump: bool = false ## caso esteja no pulo forçado
#endregion

#region dash Variables
@export_group("Dash Params")
@export var dash_apply_gravity: bool = true ## aplica a gravidade no dash
@export var dash_four_directions: bool = false ## dash para cima e baixo tambem

#endregion

#region pull Variables

var _pull_input_pressed: bool = false

#endregion

#region crouch Variables

var _crouch_input_pressed: bool = false

#endregion

#region raycasts

## raycasts para maior precisão
@export_group("Raycasts")
@export_subgroup("Bottom")
@export var rc_bottom_left:RayCast2D ## raycast da baixo esquerda
@export var rc_bottom_center:RayCast2D ## raycast da baixo centro
@export var rc_bottom_right:RayCast2D ## raycast da baixo direita

@export_subgroup("Top")
@export var rc_top_left:RayCast2D ## raycast da cima esquerda
@export var rc_top_center:RayCast2D ## raycast da cima centro
@export var rc_top_right:RayCast2D ## raycast da cima direita


@export_subgroup("Left")
@export var rc_left_top:RayCast2D ## raycast da esquerda cima
@export var rc_left_center:RayCast2D ## raycast da esquerda centro
@export var rc_left_bottom:RayCast2D ## raycast da esquerda baixo

@export_subgroup("Right")
@export var rc_right_top:RayCast2D ## raycast da direita cima
@export var rc_right_center:RayCast2D ## raycast da direita centro
@export var rc_right_bottom:RayCast2D ## raycast da direita baixo

#endregion

#region platformer Variables

var current_floor_platformer: Node2D ## minha plataforma no chão
var current_floor_surface:Surface ## minha superficie

var current_platform_velocity: Vector2  = Vector2.ZERO ## valor da velocidade da plataforma
var last_platform_velocity: Vector2  = Vector2.ZERO ## valor da ultima velocidade da plataforma

var platformer_persist_momentum_time: float = 0.4 ## tempo de persistencia do momemtum
var platformer_persist_momentum_timer: float = 0 ## temporizador do mommetum
var platformer_momentum_velocity: Vector2  = Vector2.ZERO 
#endregion


var current_pushable_platformer: Pushable


func _ready() -> void:
	super._ready()
	motion_mode = CharacterBody2D.MOTION_MODE_GROUNDED
	floor_max_angle = deg_to_rad(max_slope_angle)

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	_process_jump(delta)
	_process_fall(delta)
	_process_platformer(delta)

func do_move_and_slide() -> bool:
	_handle_through_platform()
	handle_pushable_platformer(current_delta)
	last_platform_velocity = current_platform_velocity
	current_platform_velocity = get_platform_velocity()
	
	var output = super.do_move_and_slide()
	handle_platformer()
	handle_surface()
	return output


func is_able_to_die() -> bool:
	return _die or is_able_to_die_smashed()

#region Movement
func is_able_to_move() -> bool:
	return _has_horizontal_input()

func is_able_to_stop() -> bool:
	return not _has_horizontal_input()

func horizontal_movement(delta:float,  _input:float = _horizontal_input, _max_speed:float = max_speed, _acceleration:float = acceleration, _deceleration:float = deceleration, _friction:float = friction, _turn_speed:float = turn_speed) -> void:
	if not is_on_floor():
		_max_speed    = air_max_speed    if _max_speed == max_speed       else _max_speed
		_acceleration = air_acceleration if _acceleration == acceleration else _acceleration
		_deceleration = air_deceleration if _deceleration == deceleration else _deceleration
		_friction     = air_friction     if _friction == friction         else _friction
		_turn_speed   = air_turn_speed   if _turn_speed == turn_speed     else _turn_speed
	else:
		_max_speed *= _get_slope_speed_multiplier(_input)
	
	# fricção da plataforma
	if is_on_floor() and current_floor_surface:
		var _surface_speed_multiply_factor =  current_floor_surface.surface_speed_multiply_factor
		var _surface_friction_multiply_factor =  current_floor_surface.surface_friction_multiply_factor
		# Aplica modificadores
		_max_speed *=  1 + _surface_speed_multiply_factor
		_acceleration *=  1 + _surface_speed_multiply_factor
		_turn_speed *=  1 + _surface_speed_multiply_factor
		_deceleration *=  1 + _surface_speed_multiply_factor
		_friction *= 1 + _surface_friction_multiply_factor
	
	#if platformer_momentum_velocity.x != 0 and not is_on_floor() and platformer_persist_momentum_timer > 0:
		#if _input == 0 or sign(_input) == sign(platformer_momentum_velocity.x):
			#_max_speed += platformer_momentum_velocity.x * -1
	
	velocity.x = _get_axis_movement(velocity.x, delta, _input, _max_speed, _acceleration, _deceleration, _friction, _turn_speed)
	
	# Adiciona a força da esteira, se estiver no chão
	if is_on_floor() and current_floor_surface:
		var _surface_automatic_speed =  current_floor_surface.surface_automatic_speed
		if _surface_automatic_speed != 0:
			velocity.x += _surface_automatic_speed * delta

func is_in_slope() -> bool:
	if is_on_floor() and use_slope_movement:
		var floor_angle_deg = rad_to_deg(get_floor_angle())
		if floor_angle_deg >= min_slope_angle:
			return true
	return false

func _get_slope_speed_multiplier(horizontal_input: float = _horizontal_input) -> float:
	if is_on_floor() and use_slope_movement:
		var slope_angle := rad_to_deg(get_floor_angle())
		if slope_angle < min_slope_angle or slope_angle >= max_slope_angle or _horizontal_input == 0:
			return 1.0
			
		var floor_normal = get_floor_normal()

		## Direção do movimento
		var is_horizontal_input_right = horizontal_input > 0
		var is_slope_right = floor_normal.x < 0
		
		## Se o personagem estiver indo contra a rampa (subindo)
		if is_horizontal_input_right == is_slope_right:
			return slope_up_speed_mult
		
	return 1.0

func handle_slope_slide(_delta:float, horizontal_input: float = _horizontal_input) -> void:
	if is_on_floor() and use_slope_movement:
		var floor_angle_deg = rad_to_deg(get_floor_angle())
		if floor_angle_deg >= min_slope_angle:

			# Tangente da rampa (escorregamento)
			var floor_normal = get_floor_normal()
			var slide_dir = Vector2(floor_normal.y, -floor_normal.x).normalized()
			var is_horizontal_input_right = horizontal_input > 0
			var is_slope_right = floor_normal.x < 0
			
			if horizontal_input == 0 or floor_angle_deg >= max_slope_angle or not (is_horizontal_input_right == is_slope_right):
				# Sempre escorregar pra baixo da rampa
				if slide_dir.dot(Vector2.DOWN) < 0:
					slide_dir = -slide_dir

				# Aplica escorregamento direto na velocidade
				velocity.x = slide_dir.x * slope_slide_force
				velocity.y = slide_dir.y * slope_slide_force
				if horizontal_input != 0:
					velocity.y = slide_dir.y * (slope_slide_force * slope_down_speed_mult)


#endregion

#region gravity

func is_able_to_fall() -> bool:
	if rc_bottom_center:
		return not is_on_rc_floor() and not is_on_floor() and velocity.y > 0
	return not is_on_floor() and velocity.y > 0

func is_able_to_land() -> bool:
	if rc_bottom_center:
		return is_on_rc_floor() and is_on_floor() and velocity.y == 0
	return is_on_floor() and velocity.y == 0

func is_able_to_super_land(_min_force_fall:float = 0) -> bool:
	return is_able_to_land() and abs(_last_velocity.y) >= abs(_min_force_fall)

func set_fast_fall_input_pressed(button_value: bool, delta: float) -> void:
	if button_value == false:
		_fast_fall_input_pressed = false
	else:
		_fast_fall_timer += delta
		_fast_fall_input_pressed = _fast_fall_timer >= fast_fall_hold_time

func reset_fast_fall() -> void:
	_fast_fall_timer = 0.0
	_fast_fall_input_pressed = false

func is_able_to_fast_fall() -> bool:
	return is_able_to_fall() and _fast_fall_input_pressed

func handle_gravity(delta:float, _extra_multiplier:float = 1) -> void:
	
	if not (rc_bottom_center and is_on_rc_floor()) and not is_on_floor():	
		# Modificadores de gravidade: hang time e fast fall
		var gravity_multiplier = 1.0
		# HANG TIME:
		# Se o personagem estiver subindo (velocidade Y negativa)
		# E estiver muito próximo do topo do salto (velocidade baixa),
		# então reduzimos a gravidade temporariamente para "flutuar" levemente no topo,
		# criando uma sensação de salto mais leve e responsivo
		if velocity.y < 0 and abs(velocity.y) < hang_time_threshold:
			gravity_multiplier = hang_time_gravity_multiplier
		# FAST FALL:
		# Se o personagem estiver caindo (velocidade Y positiva),
		# aplicamos um multiplicador de gravidade mais alto,
		# acelerando a queda para dar sensação de maior controle e peso.
		elif velocity.y > 0:
			gravity_multiplier = fast_fall_gravity_multiplier
		
		# Aplicar gravidade se não estiver no chão
		gravity_multiplier = gravity_multiplier * _extra_multiplier
		velocity.y += gravity * gravity_multiplier  * delta
		
		# gravidade maxima
		if velocity.y > max_gravity:
			velocity.y = max_gravity
	

func reset_velocity_y() -> void:
	velocity.y = 0
	
func _process_fall(_delta:float) -> void:
	if is_on_floor():
		reset_fast_fall()
		
#endregion

#region Jump Functions
func is_able_to_jump() -> bool:
	return _force_jump or (_jump_input_buffer_timer > 0 and _current_jump < max_jumps and (is_on_floor() or _jump_coyote_timer > 0))

func is_able_to_double_jump() -> bool:
	return _force_jump or (_jump_input_buffer_timer > 0 and _current_jump < max_jumps and max_jumps >= 2 and _current_jump >= 1 and (is_on_floor() or _jump_coyote_timer > 0 or _current_jump > 0))

func set_jump_input(_input:bool = false) -> void:
	_input_jump = _input
	
func set_jump_input_pressed(_input:bool = false) -> void:
	_input_jump_pressed = _input

func force_jump(_multiply:float = 1) -> void:
	if _multiply > 0:
		reset_jumps()
		_jump_multiply = _multiply
		_force_jump = true

func reset_jumps() -> void:
	_current_jump = 0

func handle_jump() -> void:
	# caso solte o botao de pulo ele faz um pulo mais curto
	if not _in_force_jump and _current_jump == 1 and not _input_jump_pressed and velocity.y <= -jump_cut_off_speed:
		velocity.y = -jump_cut_off_speed
	
func do_jump() -> void:
	# Dispara o salto se o personagem estiver no chão ou dentro do coyote time ou for segundo pulo,
	# e o botão de pulo foi pressionado recentemente (buffer) e não tiver atingido o maximo de pulos
	if is_able_to_jump() or is_able_to_double_jump():
		_in_force_jump = false
		_input_jump = false
		_current_jump += 1
		# Aplica a força do pulo invertendo o eixo Y
		var _jump_speed = jump_speed
		if _force_jump:
			_jump_speed = _jump_speed * _jump_multiply
			_in_force_jump = true
			_force_jump = false
			_jump_multiply = 1
		if  is_on_floor() and current_floor_surface:
				var surface_jump_multiply_stickiness = current_floor_surface.surface_jump_multiply_stickiness
				if surface_jump_multiply_stickiness > 0:
					_jump_speed = _jump_speed * ( 1 - surface_jump_multiply_stickiness)
		
		if _jump_speed > 0:
			velocity.y = -_jump_speed
		
		# Reseta o coyote time e o jump buffer após o pulo
		_jump_coyote_timer = 0
		_jump_input_buffer_timer = 0

func _process_jump(delta:float) -> void:
	if (is_on_floor() or (is_on_rc_wall_left() and is_on_rc_wall_right()) ) and velocity.y >= 0:
		# pisar no chão reseta o pulo
		reset_jumps()
		#controla o coyote time
		_jump_coyote_timer = jump_coyote_time
	else:
		_jump_coyote_timer -= delta
		
	#caso tiver apertado o pulo
	if _input_jump:
		# Ativa o temporizador de jump buffer (permite pular mesmo apertando antes de tocar no chão)
		_jump_input_buffer_timer = jump_input_buffer_time
	
	# Atualiza jump buffer timer
	if not is_able_to_jump():
		_jump_input_buffer_timer -= delta

#endregion

#region Dash

# Reseta o número de dashes usados# Reseta o número de dashes usados
func reset_dashes() -> void:
	if is_on_floor():
		current_dash = 0  # Volta o contador de dashes para 0

func get_valid_directions() -> Array:
	if dash_four_directions:
		return super.get_valid_directions()
	
	var directions = [Vector2.ZERO]
	directions.append(Vector2.LEFT)
	directions.append(Vector2.RIGHT)
	return directions

func handle_dash(delta:float, _force_direction: Vector2 = Vector2.ZERO) -> void:
	#caso o buffer tenha acabado e não tenha direção forço para onde o character esta olhando
	var _dash_direction = Vector2.ZERO
	if dash_input_buffer_timer > 0 and dash_input_buffer_timer <= delta:
		_dash_direction = get_dash_best_direction(Vector2(_last_horizontal_input,0))
		
	super.handle_dash(delta, _dash_direction)

#endregion

#region Crouch

func is_crouch_input_pressed() -> bool:
	return _crouch_input_pressed

func is_able_to_crouch() -> bool:
	return is_able_to_stop() and is_on_floor() and _crouch_input_pressed

func set_crouch_input_pressed(button_value: bool) -> void:
	_crouch_input_pressed = button_value

#endregion

#region Platformer

func _get_floor_collider(group_name: String = "") -> Node2D:
	if not is_on_floor():
		return null

	for i in get_slide_collision_count():
		var collision := get_slide_collision(i)
		if collision == null:
			continue
			
		var normal = collision.get_normal()
		var collider = collision.get_collider()
		if collider == null:
			continue
		
		# Verifica se a normal representa chão
		if normal.dot(Vector2.UP) > 0.7:
			if group_name and not collider.is_in_group(group_name):
				continue
			
			return collider

	return null

func get_floor_platformer(_group:String = Globals.GROUP_PLATFORMER) -> Node2D:
	var collider = null
	if rc_bottom_center:
		collider = _get_collider_from_raycast(rc_bottom_center,_group)
		if not collider and rc_bottom_left:
			collider = _get_collider_from_raycast(rc_bottom_left,_group)
		if not collider and rc_bottom_right:
			collider = _get_collider_from_raycast(rc_bottom_right,_group)
	else:
		collider = _get_floor_collider(_group)
		
	return collider
	
func get_floor_surface() -> Surface:
	var collider = get_floor_platformer(Globals.GROUP_SURFACE)
	
	if not collider is Surface :
		return null
	
	return collider as Surface

func get_wall_platformer(_force:bool = false, _group:String = Globals.GROUP_PLATFORMER) -> Node2D:
	var _wall_platformer: Node2D
	if (is_on_rc_wall_left() and (_force or _last_velocity.x < 0)):
		_wall_platformer = _get_collider_from_raycast(rc_left_center,_group)
		if not _wall_platformer:
			_wall_platformer = _get_collider_from_raycast(rc_left_top,_group)
		if not _wall_platformer:
			_wall_platformer = _get_collider_from_raycast(rc_left_bottom,_group)
			
	elif (is_on_rc_wall_right() and (_force or _last_velocity.x > 0)):
		_wall_platformer = _get_collider_from_raycast(rc_right_center,_group)
		if not _wall_platformer:
			_wall_platformer = _get_collider_from_raycast(rc_right_top,_group)
		if not _wall_platformer:
			_wall_platformer = _get_collider_from_raycast(rc_right_bottom,_group)
			
		
	if is_instance_valid(_wall_platformer):
		return _wall_platformer
		
	return null

func get_ceiling_platformer(_group:String = Globals.GROUP_PLATFORMER) -> Node2D:
	var collider = null
	if rc_top_center:
		collider = _get_collider_from_raycast(rc_top_center,_group)
	if not collider and rc_top_left:
		collider = _get_collider_from_raycast(rc_top_left,_group)
	if not collider and rc_top_right:
		collider = _get_collider_from_raycast(rc_top_right,_group)
	return collider

func is_on_through_platform() -> bool:
	var floor_collision = get_floor_platformer()
	if floor_collision == null:
		return false

	return floor_collision.is_in_group(Globals.GROUP_THROUGH_PLATFORMER)

func _add_platformer_velocity_to_character() -> void:
	if last_platform_velocity != Vector2.ZERO:
		velocity.x = last_platform_velocity.x
		platformer_momentum_velocity = last_platform_velocity
		last_platform_velocity = Vector2.ZERO
		platformer_persist_momentum_timer = platformer_persist_momentum_time

func _process_platformer(delta:float) -> void:
	if platformer_persist_momentum_timer > 0:
		platformer_persist_momentum_timer -= delta

func handle_platformer() -> void:
	if is_on_floor():
		if rc_bottom_center or get_slide_collision_count() > 0:
			current_floor_platformer = get_floor_platformer()
	else:
		current_floor_platformer = null
		_add_platformer_velocity_to_character()

func handle_surface() -> void:
	if is_on_floor():
		if rc_bottom_center or get_slide_collision_count() > 0:
			var floor_surface = get_floor_surface()
			if floor_surface and current_floor_surface != floor_surface:
				current_floor_surface = floor_surface
			
				floor_surface.character_touched.emit(self)
		
				var surface_bounce_multiply_factor = current_floor_surface.surface_bounce_multiply_factor
				force_jump(surface_bounce_multiply_factor)
				
	else:
		current_floor_surface = null

func _handle_through_platform() -> void:
	if _vertical_input == 1 and is_on_through_platform():
		var through_platform_down_force = 2 # força de descida da plataforma
		global_position.y += through_platform_down_force

func is_able_to_die_smashed() -> bool:
	return is_able_to_die_smashed_up_down() or is_able_to_die_smashed_left_right()

func is_able_to_die_smashed_up_down() -> bool:
	var space: float = 2.0

	var up: bool= test_move(global_transform, Vector2(0, -space))
	var down: bool= test_move(global_transform, Vector2(0, space))
	
	if up and down:
		if (is_on_floor() or is_on_rc_floor()) and (is_on_ceiling() or is_on_rc_ceiling()):
			if not current_pushable_platformer and not get_ceiling_platformer(Globals.GROUP_THROUGH_PLATFORMER):
				return true
	return false
			
func is_able_to_die_smashed_left_right() -> bool:
	#elif rc_left_center and rc_right_center and is_on_rc_wall_left() and is_on_rc_wall_right():
	#if rc_left_center and rc_right_center and rc_left_center.is_colliding() and rc_right_center.is_colliding():
		#if not current_pushable_platformer and not get_wall_pushable_platformer(true) and not get_wall_platformer(true,Globals.GROUP_THROUGH_PLATFORMER):
			#print("esmagado lado")
			#print("current_pushable_platformer ", current_pushable_platformer)
			#print("get_wall_pushable_platformer ", get_wall_pushable_platformer(true))
			#
			#return true
	#return false
	var space: float= 2.0

	var left: bool= test_move(global_transform, Vector2(-space, 0))
	var right: bool= test_move(global_transform, Vector2(space, 0))
	
	if left and right:
		if rc_left_center and rc_right_center and rc_left_center.is_colliding() and rc_right_center.is_colliding():
			if not current_pushable_platformer and not get_wall_pushable_platformer(true) and not get_wall_platformer(true,Globals.GROUP_THROUGH_PLATFORMER):
				print("morreu esmagado lado")
				return true
	return false

func test_move_left_right(space: float= 2.0) -> bool:
	var left: bool= test_move(global_transform, Vector2(-space, 0))
	var right: bool= test_move(global_transform, Vector2(space, 0))
	return left and right

#endregion

#region Platformer Push / Pull

func get_wall_pushable_platformer(_force:bool = false) -> Pushable:
	var _wall_platformer = get_wall_platformer(_force,Globals.GROUP_PUSHABLE_PLATFORMER)
	if _wall_platformer is Pushable:
		return _wall_platformer
		
	return null

func is_able_to_push_wall() -> bool:
	if current_pushable_platformer:
		return true
	
	if is_on_wall() or (is_on_rc_wall_left() and _last_horizontal_input < 0) or (is_on_rc_wall_right() and _last_horizontal_input > 0):
		return true
	
	return false

func is_pull_input_pressed() -> bool:
	return _pull_input_pressed

func set_pull_input_pressed(button_value: bool) -> void:
	_pull_input_pressed = button_value

func is_able_to_pull_wall() -> bool:
	if is_pull_input_pressed() and current_pushable_platformer and ((is_pushable_platformer_on_right() and _last_horizontal_input < 0) or (is_pushable_platformer_on_left() and _last_horizontal_input > 0)):
		return true
		
	if is_pull_input_pressed() and ((is_on_rc_wall_left() and _last_horizontal_input > 0) or (is_on_rc_wall_right() and _last_horizontal_input < 0)):
		return true
	
	return false

func clear_current_pushable_platformer() -> void:
	if current_pushable_platformer:
		current_pushable_platformer.set_holder(null)
	current_pushable_platformer = null

func handle_pushable_platformer(_delta:float, _velocity:Vector2 = velocity) -> void:
	if current_pushable_platformer:
		if _velocity.y != 0 or (is_pushable_platformer_on_right() and _velocity.x < 0 and not is_pull_input_pressed()) or (is_pushable_platformer_on_left() and _velocity.x > 0 and not is_pull_input_pressed()):
			await get_tree().physics_frame
			var _pushable_platformer = get_wall_pushable_platformer()
			if not _pushable_platformer or _pushable_platformer != current_pushable_platformer:
				clear_current_pushable_platformer()
		else:
			current_pushable_platformer.push_process(_delta, _velocity.x)
	else:
		current_pushable_platformer = get_wall_pushable_platformer()
		if current_pushable_platformer:
			current_pushable_platformer.set_holder(self)

func is_pushable_platformer_on_right() -> bool:
	if current_pushable_platformer:
		return global_position.x < current_pushable_platformer.global_position.x
	return false
	
func is_pushable_platformer_on_left() -> bool:
	if current_pushable_platformer:
		return global_position.x > current_pushable_platformer.global_position.x
	return false

#endregion

#region Raycast

func is_on_rc_floor() -> bool:
	if rc_bottom_left and rc_bottom_center and rc_bottom_right:
		return rc_bottom_left.is_colliding() or rc_bottom_center.is_colliding() or rc_bottom_right.is_colliding()
	else:
		return false

func is_on_rc_floor_center() -> bool:
	if rc_bottom_center:
		return rc_bottom_center.is_colliding()
	return false
	
func is_on_rc_floor_left_edge() -> bool:
	if rc_bottom_left and rc_bottom_right:
		return rc_bottom_right.is_colliding() and not rc_bottom_left.is_colliding()
	return false

func is_on_rc_floor_right_edge() -> bool:
	if rc_bottom_left and rc_bottom_right:
		return rc_bottom_left.is_colliding() and not rc_bottom_right.is_colliding()
	return false

func is_on_rc_ceiling() -> bool:
	if rc_top_left and rc_top_center and rc_top_right:
		return rc_top_left.is_colliding() or rc_top_center.is_colliding() or rc_top_right.is_colliding()
	else:
		return false

func is_on_rc_wall() -> bool:
	return is_on_rc_wall_left() or is_on_rc_wall_right()

func is_on_rc_wall_left() -> bool:
	if rc_left_top and rc_left_center and rc_left_bottom:
		return rc_left_top.is_colliding() or rc_left_center.is_colliding() or rc_left_bottom.is_colliding()
	return false

func is_on_rc_wall_right() -> bool:
	if rc_right_top and rc_right_center and rc_right_bottom:
		return rc_right_top.is_colliding() or rc_right_center.is_colliding() or rc_right_bottom.is_colliding()
	return false

#endregion
