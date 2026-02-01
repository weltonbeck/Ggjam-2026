extends CharacterBody2D
class_name Pushable

@export var gravity: float= 900.0
@export var min_velocity:float = 5.0
#@export var max_velocity:float = 50.0
@export var friction: float= 100.0

var holder: CharacterPlaformerBehavior = null

func _ready() -> void:
	add_to_group(Globals.GROUP_PLATFORMER)
	add_to_group(Globals.GROUP_PUSHABLE_PLATFORMER)
	motion_mode = CharacterBody2D.MOTION_MODE_GROUNDED

func _physics_process(delta):
	if not holder:
		velocity.x = move_toward(velocity.x,0,friction * delta)
		_apply_gravity(delta)
		move_and_slide()

func push_process(delta, horizontal_velocity:float = 0):
	if abs(horizontal_velocity) < min_velocity:
		horizontal_velocity = sign(horizontal_velocity) * min_velocity
	#elif abs(horizontal_velocity) > max_velocity:
		#horizontal_velocity = sign(horizontal_velocity) * max_velocity
	velocity.x = horizontal_velocity
	_apply_gravity(delta)
	move_and_slide()
	
	if holder and not is_on_floor():
		holder.clear_current_pushable_platformer()

func _apply_gravity(delta):
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0

func set_holder(player: CharacterBody2D):
	holder = player
