extends PlayerPlaformerBehavior

@export var key_change_mask:  StringName = &"key_start"
@export var state_mask: State

func _process_inputs(delta: float) -> void:
	super._process_inputs(delta)
	
	if state_mask and state_mask.has_method("set_mask_buton") and key_change_mask and InputMap.has_action(key_change_mask):
		state_mask.set_mask_buton(Input.is_action_just_pressed(key_change_mask))
