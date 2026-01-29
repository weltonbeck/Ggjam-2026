class_name PhysicsLayerMap
extends EditorPlugin

# Se quiser impedir que o plugin sobrescreva nomes já existentes,
# troque para 'false'.
const FORCE_OVERWRITE: bool = true


func create_physics_layer_map() -> void:
	_apply_names("layer_names/2d_physics", Globals.LAYERS_LIST)
	ProjectSettings.save()
	# Opcional: força o inspector a atualizar imediatamente
	# (útil se algum painel já estiver aberto)
	Engine.get_singleton("EditorInterface").inspect_object(ProjectSettings)
	print("✅ physics layer atualizados.")
	
func _apply_names(section: String, names: Dictionary) -> void:
	for i in range(1, 33):
		var key := "%s/layer_%d" % [section, i]
		var current := ProjectSettings.get_setting(key, "")
		if names.has(i):
			if FORCE_OVERWRITE or current == "":
				ProjectSettings.set_setting(key, String(names[i]))
		else:
			# Se não definiu nome para essa layer,
			# zera (apenas se estiver forçando overwrite).
			if FORCE_OVERWRITE and current != "":
				ProjectSettings.set_setting(key, "")

func remove_physics_layer_map(section: String = "layer_names/2d_physics") -> void:
	for i in range(1, 33):
		var key := "%s/layer_%d" % [section, i]
		# restaura para o padrão: ""
		ProjectSettings.set_setting(key, "")
	ProjectSettings.save()
	print("❌ Todos os physics layer foram limpos.")
