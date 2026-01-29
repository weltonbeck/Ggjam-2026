@tool
extends EditorInspectorPlugin
class_name SignalMethodSelectorInspectorPlugin

# ----------------------------------------------------------
# Plugin: adiciona botões no Inspector para selecionar
# sinais ou métodos de um Node alvo.
# Ele funciona tanto para Nodes (componentes em cena)
# quanto para Resources (ex: assets exportados).
# ----------------------------------------------------------

# Determina se o plugin deve lidar com o objeto atual no inspetor.
# Aqui ele só atua em objetos que tenham propriedades específicas
# relacionadas à seleção de sinais ou métodos.
func _can_handle(object: Object) -> bool:
	if not (object is Node) and not (object is Resource):
		return false
	
	# Coleta todos os nomes de propriedades exportadas do objeto
	var props := []
	for p in object.get_property_list():
		props.append(p.name)
	
	# Verifica se o objeto tem as combinações esperadas:
	# (target_signal_node + target_signal) ou (target_method_node + target_method)
	var has_signal_node := "target_signal_node" in props
	var has_signal := "target_signal" in props
	var has_method_node := "target_method_node" in props
	var has_method := "target_method" in props
	
	# Só ativa o plugin se houver uma dessas combinações
	return (has_signal_node and has_signal) or (has_method_node and has_method)


# ----------------------------------------------------------
# Adiciona botões personalizados ao inspetor
# ----------------------------------------------------------
func _parse_property(object: Object, type: int, path: String, hint: int, hint_text: String, usage_flags: int, wide: bool) -> bool:
	# Executa apenas para as propriedades "target_signal" e "target_method"
	if path == "target_signal" or path == "target_method":
		var prop_names := _get_prop_names(object)

		# Cria botão para seleção de sinal
		if path == "target_signal" and "target_signal_node" in prop_names:
			var btn_sig := Button.new()
			btn_sig.text = "🔎 Selecionar sinal..."
			btn_sig.tooltip_text = "Seleciona um sinal do node alvo."
			btn_sig.flat = true
			# Quando pressionado, chama o método de seleção de sinal
			btn_sig.pressed.connect(_on_select_signal_pressed.bind(object))
			# Adiciona o botão no inspetor
			add_property_editor("target_signal_selector", btn_sig)

		# Cria botão para seleção de método
		if path == "target_method" and "target_method_node" in prop_names:
			var btn_meth := Button.new()
			btn_meth.text = "🔎 Selecionar método..."
			btn_meth.tooltip_text = "Seleciona um método do node alvo."
			btn_meth.flat = true
			# Quando pressionado, chama o método de seleção de método
			btn_meth.pressed.connect(_on_select_method_pressed.bind(object))
			add_property_editor("target_method_selector", btn_meth)

	return false


# Retorna apenas os nomes das propriedades do objeto
func _get_prop_names(object: Object) -> Array:
	var props := []
	for p in object.get_property_list():
		props.append(p.name)
	return props


# ----------------------------------------------------------
# --- Seleção de Sinais ---
# ----------------------------------------------------------
func _on_select_signal_pressed(target_object: Object) -> void:
	# Resolve o Node real, mesmo que a propriedade seja um NodePath (em Resources)
	var node = _resolve_target_node(target_object, "target_signal_node")
	
	# Caso o Node não exista ou não seja válido
	if node == null or not is_instance_valid(node):
		_show_editor_alert("Defina um 'target_signal_node' válido antes de selecionar um sinal.")
		return

	# Obtém a lista de sinais públicos do node
	var signals: Array = []
	for s in node.get_signal_list():
		signals.append(s.name)

	# Caso o node não tenha sinais
	if signals.is_empty():
		_show_editor_alert("O node '%s' não possui sinais públicos." % node.name)
		return

	# Cria a janela popup para o usuário escolher o sinal
	_create_selection_popup("Selecionar sinal de %s" % node.name, signals, target_object, "target_signal")


# ----------------------------------------------------------
# --- Seleção de Métodos ---
# ----------------------------------------------------------
func _on_select_method_pressed(target_object: Object) -> void:
	var node = _resolve_target_node(target_object, "target_method_node")
	if node == null or not is_instance_valid(node):
		_show_editor_alert("Defina um 'target_method_node' válido antes de selecionar um método.")
		return

	# Coleta todos os métodos públicos possíveis
	var methods := []
	var script := node.get_script()
	
	# Inclui métodos definidos no script do Node (se existir)
	if script:
		for m in script.get_script_method_list():
			if _accept_method(m.name):
				methods.append(m.name)

	# Inclui métodos herdados da classe do Node (excluindo duplicados)
	for m in node.get_method_list():
		if not methods.has(m.name) and _accept_method(m.name):
			methods.append(m.name)
	
	# Caso o node não tenha métodos públicos válidos
	if methods.is_empty():
		_show_editor_alert("Nenhum método público encontrado em '%s'." % node.name)
		return

	# Cria o popup para o usuário escolher o método
	_create_selection_popup("Selecionar método de %s" % node.name, methods, target_object, "target_method")


# ----------------------------------------------------------
# --- Resolve Node real a partir de Node ou NodePath ---
# ----------------------------------------------------------
func _resolve_target_node(target_object: Object, prop_name: String) -> Node:
	var value = target_object.get(prop_name)
	
	# Caso 1: a propriedade já é um Node (usado em componentes na cena)
	if value is Node:
		return value
	
	# Caso 2: é um NodePath (usado em Resources)
	if value is NodePath:
		# Obtém o root da cena atual ou o primeiro nó selecionado
		var root = EditorInterface.get_edited_scene_root()
		var selection = EditorInterface.get_selection().get_selected_nodes()
		if not selection.is_empty():
			root = selection[0]
		
		# Tenta resolver o NodePath relativo ao root atual
		if root and value != NodePath(""):
			var node := root.get_node_or_null(value)
			if node:
				return node
	
	return null


# ----------------------------------------------------------
# --- Criação do Popup + Filtro de Busca ---
# ----------------------------------------------------------
func _create_selection_popup(title: String, items: Array, target_object: Object, prop_name: String) -> void:
	# Cria janela de diálogo
	var popup := AcceptDialog.new()
	popup.title = title
	popup.min_size = Vector2(380, 420)

	# Cria layout vertical
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 8)

	# Label superior
	var lbl := Label.new()
	lbl.text = "Digite para filtrar:"
	root.add_child(lbl)

	# Campo de busca
	var search := LineEdit.new()
	search.placeholder_text = "Filtrar por nome..."
	root.add_child(search)

	# Área de rolagem para listar itens
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# Container para botões de itens
	var vb := VBoxContainer.new()
	vb.name = "ListContainer"
	scroll.add_child(vb)
	root.add_child(scroll)
	popup.add_child(root)

	# Adiciona popup ao editor
	EditorInterface.get_editor_main_screen().add_child(popup)

	# Guarda metadados no popup (usado ao filtrar)
	popup.set_meta("items", items)
	popup.set_meta("list_container", vb)
	popup.set_meta("target_object", target_object)
	popup.set_meta("prop_name", prop_name)

	# Conecta filtro de texto
	search.text_changed.connect(_on_filter_text_changed.bind(popup))

	# Popula a lista inicial
	_populate_popup_list(popup, "")

	# Exibe popup centralizado
	popup.popup_centered(Vector2(400, 440))


# Atualiza a lista ao digitar no campo de filtro
func _on_filter_text_changed(filter_text: String, popup: AcceptDialog) -> void:
	_populate_popup_list(popup, filter_text)


# Cria os botões dos itens no popup
func _populate_popup_list(popup: AcceptDialog, filter_text: String) -> void:
	var vb: VBoxContainer = popup.get_meta("list_container")
	var items: Array = popup.get_meta("items")
	var target_object: Object = popup.get_meta("target_object")
	var prop_name: String = popup.get_meta("prop_name")

	# Remove botões antigos antes de atualizar
	for c in vb.get_children():
		c.queue_free()

	# Cria um botão para cada item que passa no filtro
	for item in items:
		if filter_text == "" or item.to_lower().contains(filter_text.to_lower()):
			var b := Button.new()
			b.text = item
			b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			b.alignment = HORIZONTAL_ALIGNMENT_LEFT

			# Quando clicado, define o valor da propriedade e fecha o popup
			var on_press := func():
				target_object.set(prop_name, item)
				popup.hide()
				popup.queue_free()

			b.pressed.connect(on_press)
			vb.add_child(b)


# ----------------------------------------------------------
# --- Funções Utilitárias ---
# ----------------------------------------------------------

# Filtra métodos válidos (ignora internos e getters/setters)
func _accept_method(name: String) -> bool:
	return not (name.begins_with("_") or name.begins_with("get_") or name.begins_with("set_") or name.begins_with("is_"))

# Exibe um popup simples com uma mensagem de alerta no editor
func _show_editor_alert(text: String) -> void:
	var d := AcceptDialog.new()
	d.title = "Signal Selector"
	d.dialog_text = text
	EditorInterface.get_editor_main_screen().add_child(d)
	d.popup_centered(Vector2(320, 120))
