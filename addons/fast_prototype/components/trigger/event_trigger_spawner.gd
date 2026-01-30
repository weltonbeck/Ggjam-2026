@icon("res://addons/fast_prototype/assets/icons/trigger.svg")
extends EventTriggerBase

## Cena que será instanciada quando o trigger for ativado.
@export var packed_scene: PackedScene

## Nó pai opcional para a instância criada.
## Se não for definido, a cena será adicionada à root da árvore.
@export_group("Spawned Parent")
@export var parent_node_path: NodePath

## Executado quando o sinal monitorado é disparado.
func on_trigger_active() -> void:
	# Instancia a cena configurada, se existir.
	if packed_scene:
		var _instance = packed_scene.instantiate()

		# Define o nó pai da instância.
		var parent_node: Node
		if parent_node_path:
			parent_node = get_node_or_null(parent_node_path)
			
		if parent_node:
			parent_node.add_child(_instance)
		else:
			get_tree().root.add_child(_instance)

		# Posiciona a instância no mesmo ponto global do trigger.
		if _instance is Node2D:
			_instance.global_position = global_position
