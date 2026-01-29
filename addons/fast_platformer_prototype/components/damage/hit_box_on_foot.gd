extends HitBox
class_name HitBoxOnFoot

@export var behavior:CharacterPlaformerBehavior
@export var jump_multiply:float = 1

@export_group("Intagible")
@export var life_points: LifePoints
@export var intangible_time:float = 0.1

func _on_area_entered(area:Area2D) -> void:
	if behavior and behavior.velocity.y > 0:
		
		if life_points and intangible_time:
			life_points.set_intagible(intangible_time)
		
		super._on_area_entered(area)
		if area is HurtBox:
			behavior.velocity.y = 0
			behavior.force_jump(jump_multiply)
