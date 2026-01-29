@tool
extends EditorPlugin

var editor_input_map = EditorInputMap.new()
var physics_layer_map = PhysicsLayerMap.new()
var singleton_configure = SingletonConfigurePlugin.new()
var audio_configure = AudioConfigurePlugin.new()
var editorInspectorPlugin = SignalMethodSelectorInspectorPlugin.new()

func _enable_plugin() -> void:
	editor_input_map.create_input_map()
	physics_layer_map.create_physics_layer_map()
	singleton_configure.create()
	audio_configure.create()

func _disable_plugin() -> void:
	editor_input_map.remove_input_map()
	physics_layer_map.remove_physics_layer_map()
	singleton_configure.remove()
	audio_configure.remove()

func _enter_tree() -> void:
	add_inspector_plugin(editorInspectorPlugin)
	print("✅ Inspector plugin registrado:", editorInspectorPlugin)


func _exit_tree() -> void:
	remove_inspector_plugin(editorInspectorPlugin)
	print("❌ Inspector plugin removido")
