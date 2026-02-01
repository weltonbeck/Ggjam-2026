extends Node

const SAVE_SECRET = "123456"
var save_helper = SaveHelper.new()


func save_game(slot:int = 1) -> void:
	var data:Dictionary = {}
	
	# Integra automaticamente o GameStateManager (se estiver presente no projeto)
	# Isto permite salvar progressos globais (missões, flags, valores persistentes).
	if GameStateManager:
		data["game_state"] = GameStateManager.serialize()
	
	if save_helper:
		save_helper.save_game(slot,data,true, true, SAVE_SECRET)
		
func load_game(slot:int = 1) -> void:
	var data:Dictionary = {}
	
	if save_helper:
		data = save_helper.load_game(slot,true,true,SAVE_SECRET)
	
	if GameStateManager and data.get("game_state"):
		GameStateManager.deserialize(data.get("game_state"))
