extends CharacterPlaformerBehavior
class_name SimplePatrolPlaformerBehavior

@export var walk: bool = true ## estado de movimento
var _walk:bool = false

@export var initial_direction: Vector2 = Vector2.LEFT
var flip_cooldown: float = 0.2  # tempo entre mudanças de direção (em segundos)

@export_group("Player Detection")
@export var player_detector:PlayerDetector
@export var stop_after_time:float = 3.0
var stop_after_timer:float = 0
var loose_player:bool = false


@export_group("change on hurt")
@export var run_on_hurt:bool = true
@export var life_points: LifePoints


var _input: Vector2
var _flip_timer := 0.0

func _ready() -> void:
	super._ready()
	_walk = walk
	_input = initial_direction
	set_input(_input)
	if life_points:
		life_points.take_damage.connect(_on_take_damage)
	
	if player_detector:
		player_detector.player_entered.connect(_on_player_entered)
		player_detector.player_exited.connect(_on_player_exited)
	
func _on_take_damage(_amount:float, _diretion:Vector2) -> void:
	if run_on_hurt:
		if _diretion.x > 0:
			_input = Vector2(1,0)
		elif _diretion.x < 0:
			_input = Vector2(-1,0)
		_flip_timer = flip_cooldown
	
func _on_player_entered(_player:CharacterBehavior) -> void:
	if not _walk:
		start_walk()
		
func _on_player_exited(_player:CharacterBehavior) -> void:
	if _walk and stop_after_time:
		loose_player = true
		stop_after_timer = stop_after_time

func _process_inputs(delta: float) -> void:
	if _walk:
		if _flip_timer > 0.0:
			_flip_timer -= delta

		if is_on_wall() and _flip_timer <= 0.0:
			_input = -_input
			_flip_timer = flip_cooldown  # inicia o cooldown

		set_input(_input)
	else:
		set_input(Vector2.ZERO)
		
	if loose_player and stop_after_timer > 0:
		stop_after_timer -= delta
		if stop_after_timer <= 0:
			loose_player = false
			lose_player()
			
func lose_player() -> void:
	start_walk()


func start_walk() -> void:
	_walk = true
	
func stop_walk() -> void:
	_walk = false
