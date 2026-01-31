@icon("res://addons/fast_prototype/assets/icons/life_points.svg")
extends Node
class_name LifePoints

@export var max_life: float = 2
@export var intangible_time:float = 0.2


@export_category("Game State")
@export_placeholder("player") var game_state_prefix: String = "" ## collectable.name


var _is_intagible:float = false
var _current_life: int

signal change()
signal take_damage(amount:float,diretion:Vector2)
signal recover_health(amount:float)
signal die()

func _ready() -> void:
	_current_life = max_life
	change_life()

func set_intagible(_intagible_time:float) -> void:
	if not _is_intagible:
		_is_intagible = true
		await get_tree().create_timer(_intagible_time, false).timeout
		_is_intagible = false

func apply_damage(amount:float, diretion:Vector2 = Vector2.ZERO) -> void:
	if not _is_intagible:
		_is_intagible = true
		_current_life -= amount
		take_damage.emit(amount,diretion)
		change_life()
		if (_current_life <= 0):
			die.emit()
		
		if intangible_time:
			await get_tree().create_timer(intangible_time, false).timeout
		_is_intagible = false

func recover(amount:float) -> void:
	_current_life += amount
	if (_current_life > max_life):
		_current_life = max_life
	change_life()
	recover_health.emit(amount)

func change_life() -> void:
	change.emit()
	# caso tenha o game_state_key
	if game_state_prefix:
		GameStateManager.set_state(game_state_prefix+".life", _current_life)
		GameStateManager.set_state(game_state_prefix+".max_life", max_life)
