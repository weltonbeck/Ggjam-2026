@tool
extends CharacterBody2D

# --- SETTINGS ---
@export_group("Drone Settings")
@export var health: int = 3 # Vida do drone
@export var speed: float = 100.0
@export var bullet_scene: PackedScene
@export var is_patrolling: bool = true
@export var shoot_interval: float = 1.0
@export var patrol_distance: float = 200.0 :
	set(value):
		patrol_distance = value
		queue_redraw()
@export var chase_range: float = 300.0 

# --- STATE MACHINE ---
enum State { PATROL, ATTACK, DEAD } # Adicionado estado DEAD
var current_state = State.PATROL
var target_player = null 

# --- INTERNAL VARS ---
var start_x: float 
var direction: int = 1

# --- NODES ---
@onready var pivot = $Pivot 
@onready var sprite_2d: AnimatedSprite2D = $Pivot/Sprite2D
@onready var ray_cast_2d = $Pivot/RayCast2D 
@onready var muzzle = $Pivot/Muzzle           
@onready var shoot_timer = $ShootTimer
# Adicione a referência para a colisão se quiser desativar ela ao morrer (opcional)
@onready var collision_shape = $CollisionShape2D 

func _ready():
	if not Engine.is_editor_hint():
		await get_tree().process_frame
		start_x = global_position.x


func _physics_process(_delta):
	if Engine.is_editor_hint():
		queue_redraw()
		return


	if current_state == State.DEAD:
		return

	match current_state:
		State.PATROL:
			_patrol_logic()
		State.ATTACK:
			_attack_logic()

	move_and_slide()
	
	if direction != 0:
		pivot.scale.x = abs(pivot.scale.x) * direction

# --- SISTEMA DE DANO E MORTE ---

func take_damage(amount: int):

	if current_state == State.DEAD:
		return
		
	health -= amount

	if health <= 0:
		die()

func die():
	current_state = State.DEAD
	shoot_timer.stop() 
	velocity = Vector2.ZERO 
	
	# Opcional: Desativar colisão para o player não bater na explosão
	collision_shape.set_deferred("disabled", true)

	sprite_2d.play("exploding")
	await sprite_2d.animation_finished
	queue_free()

# --- LÓGICA DE MOVIMENTO ---

func _patrol_logic():
	if not is_patrolling:
		velocity.x = 0
		return
	
	velocity.x = speed * direction

	if ray_cast_2d.is_colliding():
		direction *= -1
		return

	if patrol_distance > 0:
		var dist = global_position.x - start_x
		
		if dist > patrol_distance and direction == 1:
			direction = -1
		elif dist < -patrol_distance and direction == -1:
			direction = 1

func _attack_logic():
	velocity.x = 0 
	
	if target_player:
		var dist_to_player = global_position.distance_to(target_player.global_position)
		if dist_to_player > chase_range:
			current_state = State.PATROL
			target_player = null
			shoot_timer.stop()
			return

		var diff_x = target_player.global_position.x - global_position.x
		var deadzone = 20.0 

		if diff_x > deadzone:
			direction = 1
		elif diff_x < -deadzone:
			direction = -1 
	else:
		current_state = State.PATROL
		target_player = null

# --- SINAIS ---
func _on_hit_area_body_entered(body):
	if Engine.is_editor_hint(): return 
	if current_state == State.DEAD: return # Morto não detecta player

	if body.is_in_group("player"): 
		current_state = State.ATTACK
		target_player = body
		shoot_timer.start(0.3) 
		shoot_timer.wait_time = shoot_interval 

func _on_hit_area_body_exited(body):
	if Engine.is_editor_hint(): return
	if body == target_player:
		current_state = State.PATROL
		target_player = null
		shoot_timer.stop()

func _on_shoot_timer_timeout():
	if current_state == State.ATTACK and bullet_scene and is_instance_valid(target_player):
		var bullet = bullet_scene.instantiate()
		bullet.global_position = muzzle.global_position
		bullet.direction = muzzle.global_position.direction_to(target_player.global_position)
		bullet.rotation = bullet.direction.angle()
		get_parent().add_child(bullet)

func _draw():
	if Engine.is_editor_hint():
		draw_line(Vector2(-patrol_distance, 0), Vector2(patrol_distance, 0), Color.RED, 2.0)
		draw_line(Vector2(-patrol_distance, -10), Vector2(-patrol_distance, 10), Color.RED, 2.0)
		draw_line(Vector2(patrol_distance, -10), Vector2(patrol_distance, 10), Color.RED, 2.0)
