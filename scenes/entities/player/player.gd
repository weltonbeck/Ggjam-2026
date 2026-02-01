extends PlayerPlaformerBehavior
class_name Player

@export var key_change_mask:  StringName = &"key_start"
@export var state_mask: State

@onready var state_run: State = $StateMachine/Run
@onready var state_shoot: State = $StateMachine/Shoot
@onready var state_dash: State = $StateMachine/Dash

@onready var hit_box_power: HitBox = $HitBoxPower

var bullet_fogo = preload("res://scenes/entities/player/bullet_fogo.tscn")
var bullet_medusa = preload("res://scenes/entities/player/bullet_medusa.tscn")

func _ready() -> void:
	super._ready()
	if state_mask:
		state_mask.put_mask.connect(_on_put_mask)
		state_mask.remove_mask.connect(_on_remove_mask)
	_on_remove_mask()

func _process_inputs(delta: float) -> void:
	super._process_inputs(delta)
	
	#if state_mask and state_mask.has_method("set_mask_buton") and key_change_mask and InputMap.has_action(key_change_mask):
		#state_mask.set_mask_buton(Input.is_action_just_pressed(key_change_mask))

func _on_put_mask(_mask_type:String = "") -> void:
	_on_remove_mask()
	if _mask_type == "fogo":
		state_shoot.activate()
		max_speed = 250
		air_max_speed = 300
		state_run.animated_sprite_animation_name = "run"
		bullet_scene = bullet_fogo
		key_shoot = &"key_button_x"
		key_attack = &""
		dash_apply_gravity = false
		state_dash.animated_sprite_animation_name = "power"
		dash_speed = 650
		state_dash.hit_box = hit_box_power
		state_dash.animation_tree_animation_name = "super_dash"
		state_dash.animation_tree_blend_param = "parameters/super_dash/blend_position"
		dash_cooldown_time = 0.4
		
func _on_remove_mask() -> void:
	state_shoot.deactivate()
	max_speed = 200
	air_max_speed = 250
	state_run.animated_sprite_animation_name = "walk"
	bullet_scene = null
	key_attack = &"key_button_x"
	key_shoot = &""
	dash_apply_gravity = true
	state_dash.animated_sprite_animation_name = "roll"
	dash_speed = 500
	state_dash.hit_box = null
	state_dash.animation_tree_animation_name = "dash"
	state_dash.animation_tree_blend_param = "parameters/dash/blend_position"
	dash_cooldown_time = 0.2
