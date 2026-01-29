extends Area2D
class_name HurtBox


@export var life_points: LifePoints

signal take_damage(hit_box:HitBox, amount:float)

func set_damage(hit_box:HitBox, amount:float) -> void:
	take_damage.emit(hit_box, amount)
	
	var direction = (global_position - hit_box.global_position).normalized()
	if hit_box is HitBoxOnFoot:
		direction = Vector2.ZERO
	
	if (life_points):
		life_points.apply_damage(amount, direction)
