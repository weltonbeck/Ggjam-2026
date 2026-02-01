extends HitBox
class_name Bullet

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


func set_direction(dir: Vector2) -> void:
	direction = dir.normalized()


func _on_body_entered(body) -> void:
	if not body is Player:
		did_damage.emit(null,0)
	
	
func _on_did_damage(_body,_value) -> void:
	await get_tree().process_frame
	call_deferred("queue_free")
	
