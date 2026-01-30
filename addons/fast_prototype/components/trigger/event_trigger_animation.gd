@icon("res://addons/fast_prototype/assets/icons/trigger.svg")
extends EventTriggerBase

## Animação que sera trocada quando o trigger for ativado.
@export var animation_player: AnimationPlayer

## nome da animação que sera trocada quando o trigger for ativado.
@export var animation_name: String


## Executado quando o sinal monitorado é disparado.
func on_trigger_active() -> void:
	if animation_player and animation_name and animation_player.has_animation(animation_name):
		animation_player.play(animation_name)
	
	
