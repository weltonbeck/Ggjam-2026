extends Area2D

@export var speed: float = 400.0
var direction: Vector2 = Vector2.RIGHT

func _process(delta):
	position += direction * speed * delta

func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free()

func _on_body_entered(body):
	if "drone" not in body.name.to_lower(): 
		queue_free()
