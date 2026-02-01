@tool
extends Collectable

enum TYPES {FOGO,MEDUSA,CAVALEIRO,TENGU}

@export var type:TYPES = TYPES.FOGO 
@export var texture_masked:SpriteFrames

func _ready() -> void:
	game_state_key = _get_game_state_key_from_type()
	super._ready()

func get_type_name() -> String:
	return TYPES.keys()[type].to_lower()

func _get_game_state_key_from_type() -> String:
	# Converte enum → nome → lowercase
	var type_name = TYPES.keys()[type].to_lower()
	return "masks.%s" % String(type_name)
