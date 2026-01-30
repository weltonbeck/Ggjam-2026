extends Area2D

@export var speed: float = 400.0
var direction: Vector2 = Vector2.RIGHT

func _process(delta):
	position += direction * speed * delta

# Destroy bullet when it leaves the screen
func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free()

func _on_body_entered(body):
	if body.name == "Player":
		# Add logic to damage player here (e.g., body.take_damage())
		queue_free()
	elif body.name != "Drone": 
		# Destroy bullet on wall hit, ignore the Drone itself
		queue_free()
