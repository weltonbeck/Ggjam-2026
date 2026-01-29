extends EditorPlugin
class_name SingletonConfigurePlugin

var singletons = [{
	"name": "SceneManager",
	"path": "res://addons/fast_prototype/singletons/scene_manager.gd",
}, {
	"name": "AudioManager",
	"path": "res://addons/fast_prototype/singletons/audio_manager.gd",
}, {
	"name": "GameStateManager",
	"path": "res://addons/fast_prototype/singletons/game_state_manager.gd"
}, {
	"name": "GameManager",
	"path": "res://addons/fast_prototype/singletons/game_manager.gd"
}]

func create():
	for singleton in singletons:
		if not ProjectSettings.has_setting("autoload/" + singleton.get("name")):
			add_autoload_singleton(singleton.get("name"), singleton.get("path"))
			print("✅ Singleton " + singleton.get("name") + " adicionado!")
			
func remove():
	for singleton in singletons:
		if ProjectSettings.has_setting("autoload/" + singleton.get("name")):
			remove_autoload_singleton(singleton.get("name"))
			print("❌ Singleton " + singleton.get("name") + " removido!")
