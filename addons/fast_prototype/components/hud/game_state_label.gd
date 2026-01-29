extends RichTextLabel

@export var game_state_key: String = ""

@export_category("Default Text")
@export_multiline  var previous_text: String = ""
@export var default_text:String = ""
@export var pad_zero:int = 0
@export_multiline  var next_text: String = ""

func _ready() -> void:
	if GameStateManager:
		GameStateManager.connect("state_changed", _on_state_changed)
	parse_text()
	
func _on_state_changed(key:String, value) -> void:
	if key == game_state_key:
		parse_text(str(value))
		
func parse_text(value:String = "") -> void:
	var new_text = ""
	
	if not value:
		value = default_text
		
	if previous_text:
		new_text += previous_text
	
	if pad_zero:
		new_text += value.pad_zeros(pad_zero)
	else:
		new_text += value
	
	if next_text:
		new_text += next_text
	
	text = new_text
	
