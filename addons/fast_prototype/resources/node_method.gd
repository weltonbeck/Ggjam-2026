@tool
extends Resource
class_name NodeMethod

@export var target_method_node: NodePath
@export var target_method: String

func call_method(parent:Node2D) -> void:
	if target_method_node and target_method:
		var method_node = parent.get_node_or_null(target_method_node)
		if method_node and is_instance_valid(method_node) and method_node.has_method(target_method):
			method_node.call_deferred(target_method)
	
