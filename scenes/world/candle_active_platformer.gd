extends Area2D

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

var _active = false

signal trigger_active

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	
func _on_area_entered(_area:Area2D) -> void:
	if not _active:
		_active = true
		animated_sprite_2d.play("active")
		trigger_active.emit()
		if _area is Bullet:
			_area.did_damage.emit(null,0)
