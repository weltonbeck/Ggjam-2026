extends CanvasLayer


func _ready() -> void:
	#hide()
	pass


func _on_quit_button_pressed() -> void:
	get_tree().quit()


func _on_retry_button_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

#Função para conectar no sinal da morte do player
func show_menu():
	get_tree().paused = true
	show()


func _on_select_stage_button_pressed() -> void:
	get_tree().paused = false
	SceneManager.change_scene("res://screens/select_level.tscn")
