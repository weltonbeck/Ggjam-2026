@tool
extends Path2D

@onready var path_follow_2d: PathFollow2D = $PathFollow2D
@onready var remote_transform_2d: RemoteTransform2D = $PathFollow2D/RemoteTransform2D

enum Movements {Loop, PingPong, OneHit}

@export var is_active: bool = true ## estado de movimento da plataforma

@export var platformer: Platformer:
		set(value):
			platformer = value
			if platformer and is_inside_tree():
				_update_remote_path()
				
@export_category("Movement Speed")
@export var movement_mode: Movements = Movements.Loop ## movimentação da plataforma
@export var speed:float = 100 ## velocidade maxima
@export var wait_time: float = 1.0  ## Tempo de espera entre loops ou ping-pong
@export var initial_progress:float = 0:
		set(value):
			initial_progress = value
			if platformer and is_inside_tree():
				_update_remote_path()

@onready var path_progress:float = initial_progress
@onready var path_length: float = curve.get_baked_length()
var direction: float = 1.0 ## 1 para frente, -1 para trás
var wait_timer: float = 0.0
var waiting: bool = false

func _ready() -> void:
	if platformer:
		_update_remote_path()

func _update_remote_path():
	remote_transform_2d.remote_path = platformer.get_path()
	path_follow_2d.set_progress(initial_progress)

func _physics_process(delta: float) -> void:
	if not Engine.is_editor_hint():
		if is_active:
			
			# Se estiver esperando, desconta o tempo e sai
			if waiting:
				wait_timer -= delta
				if wait_timer <= 0.0:
					waiting = false
				else:
					return

			path_progress += delta * speed * direction
			
			match movement_mode:
				Movements.Loop:
					if path_progress >= path_length:
						path_progress = fmod(path_progress, path_length)
						waiting = true
						wait_timer = wait_time
				Movements.PingPong:
					if path_progress >= path_length:
						path_progress = path_length
						direction = -1.0
						waiting = true
						wait_timer = wait_time
					elif path_progress <= 0:
						path_progress = 0
						direction = 1.0
						waiting = true
						wait_timer = wait_time
					

				Movements.OneHit:
					if path_progress >= path_length:
						path_progress = path_length
						is_active = false
			
			path_follow_2d.set_progress(path_progress)


func activate():
	if not is_active:
		is_active = true
