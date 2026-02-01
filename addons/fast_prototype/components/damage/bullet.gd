extends HitBox
class_name Bullet

@export var turn_stone: bool = false

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

@export var speed: float = 100
var direction = Vector2.ZERO

func _ready() -> void:
	super._ready()
	body_entered.connect(_on_body_entered)
	did_damage.connect(_on_did_damage)
	
func _process(delta: float) -> void:
	if direction == Vector2.ZERO:
		return
	
	global_position += direction * speed * delta
	
	if animated_sprite_2d and direction.x < 0:
			animated_sprite_2d.flip_h = true

func set_direction(dir: Vector2) -> void:
	direction = dir.normalized()

func _on_area_entered(area:Area2D) -> void:
	if turn_stone and area is HurtBox:
		var _parent = area.get_parent()
		if _parent is Enemy:
			_parent.turn_stone()
			did_damage.emit(null,0)
			return
	super._on_area_entered(area)

func _on_body_entered(body) -> void:
	if not body is Player:
		did_damage.emit(null,0)
	
	
func _on_did_damage(_body,_value) -> void:
	await get_tree().process_frame
	call_deferred("queue_free")
	
