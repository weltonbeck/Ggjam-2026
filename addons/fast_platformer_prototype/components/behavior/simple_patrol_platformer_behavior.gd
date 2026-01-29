extends CharacterPlaformerBehavior

@export var initial_direction: Vector2 = Vector2.LEFT
var flip_cooldown: float = 0.2  # tempo entre mudanças de direção (em segundos)

@export_group("change on hurt")
@export var run_on_hurt:bool = true
@export var life_points: LifePoints

var _input: Vector2
var _flip_timer := 0.0

func _ready() -> void:
	super._ready()
	_input = initial_direction
	
	if life_points:
		life_points.take_damage.connect(_on_take_damage)

func _on_take_damage(_amount:float, _diretion:Vector2) -> void:
	if run_on_hurt:
		if _diretion.x > 0:
			_input = Vector2(1,0)
		elif _diretion.x < 0:
			_input = Vector2(-1,0)
		_flip_timer = flip_cooldown
	

func _process_inputs(delta: float) -> void:
	if _flip_timer > 0.0:
		_flip_timer -= delta

	if is_on_wall() and _flip_timer <= 0.0:
		_input = -_input
		_flip_timer = flip_cooldown  # inicia o cooldown

	set_input(_input)
