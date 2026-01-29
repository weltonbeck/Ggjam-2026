extends Area2D
class_name HitBox

@export var damage:float = 1

@export var active: bool = true
## Se true, o hit sera executado apenas uma vez
@export var hit_once: bool = false

@export_group("Dano contínuo")
## se o dano é continuo 
@export var damage_continuous: bool = false
@export var time_interval:float = 0.5

var hurt_boxes: Array[HurtBox] = []

signal did_damage(hurtBox:HurtBox, damage)

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)

func _physics_process(_delta: float) -> void:
	if active:
		if hurt_boxes.size() > 0:
			var _hurt_boxes = hurt_boxes.duplicate()
			hurt_boxes.clear()
			for h in _hurt_boxes:
				if h.has_method("set_damage"):
					h.set_damage(self,damage)
					did_damage.emit(h,damage)
			
			if damage_continuous:
				deactivate()
				await get_tree().create_timer(time_interval, false).timeout
				activate()
			elif hit_once:
				active = false
			
func _on_area_entered(area:Area2D) -> void:
	if area is HurtBox:
		hurt_boxes.append(area)

func _on_area_exited(area:Area2D) -> void:
	if area is HurtBox:
		var _hurt_boxes = hurt_boxes.duplicate()
		hurt_boxes.clear()
		for h in _hurt_boxes:
			if h != area:
				hurt_boxes.append(h)

func activate() -> void:
	set_deferred("monitoring", true)
	active = true

func deactivate() -> void:
	active = false
	set_deferred("monitoring", false)
