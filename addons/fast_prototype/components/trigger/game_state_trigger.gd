@icon("res://addons/fast_prototype/assets/icons/trigger.svg")
extends Node2D

@export var game_state_key: String = ""


## Sinal emitido sempre que o trigger é ativado.
## Pode ser usado por outros sistemas (ex: VFX, som, lógica extra).
signal triggered


func _ready() -> void:
	if GameStateManager:
		GameStateManager.connect("state_changed", _on_state_changed)
	
		if GameStateManager.has_state(game_state_key):
			triggered.emit()
	
func _on_state_changed(key:String, value) -> void:
	if key == game_state_key:
		triggered.emit()
		
