extends CanvasLayer

@export var player:PlayerPlaformerBehavior

func _ready() -> void:
	hide()
	if player:
		player.character_die.connect(show_menu)


func _on_quit_button_pressed() -> void:
	get_tree().quit()


func _on_retry_button_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

#Função para conectar no sinal da morte do player
func show_menu():
	await get_tree().create_timer(0.5, false).timeout
	get_tree().paused = true
	show()


func _on_select_stage_button_pressed() -> void:
	get_tree().paused = false
	SceneManager.change_scene("res://screens/select_level.tscn")
