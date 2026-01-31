@tool
extends Collectable

enum TYPES {FOGO,MEDUSA,CAVALEIRO,TENGU}

@export var type:TYPES = TYPES.FOGO 

func _ready() -> void:
	game_state_key = "masks.fogo" 
	super._ready()
	
