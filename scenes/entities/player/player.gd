extends PlayerPlaformerBehavior
class_name Player

@export var key_change_mask:  StringName = &"key_start"
@export var state_mask: State

@onready var state_run: State = $StateMachine/Run
@onready var state_shoot: State = $StateMachine/Shoot
@onready var state_dash: State = $StateMachine/Dash
@onready var state_fall: State = $StateMachine/Fall
@onready var state_double_jump: State = $StateMachine/DoubleJump

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
		max_speed = 250
		air_max_speed = 300
		state_shoot.activate()
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
	elif _mask_type == "tengu":
		state_double_jump.activate()
		max_speed = 250
		air_max_speed = 300
		state_run.animated_sprite_animation_name = "run"
		max_jumps = 2
		state_dash.animated_sprite_animation_name = "power"
		dash_speed = 0
		state_dash.hit_box = hit_box_power
		state_dash.animation_tree_animation_name = "super_dash"
		state_dash.animation_tree_blend_param = "parameters/super_dash/blend_position"
		dash_cooldown_time = 0.3
	elif _mask_type == "cavaleiro":
		air_max_speed = 200
		jump_speed = 500.0
		state_run.animated_sprite_animation_name = "run"
		state_dash.animated_sprite_animation_name = "shoot"
		dash_speed = 0
		state_dash.animation_tree_animation_name = "base"
		dash_cooldown_time = 0.1
		dash_duration_time = 1
	elif _mask_type == "medusa":
		state_shoot.activate()
		bullet_scene = bullet_medusa
		key_shoot = &"key_button_x"
		key_attack = &""
		
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
	state_double_jump.deactivate()
	max_jumps = 1
	dash_duration_time = 0.5
	jump_speed = 600.0
