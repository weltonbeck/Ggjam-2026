@tool
extends Resource
class_name NodeSignal

@export var target_signal_node: NodePath
@export var target_signal: String

func connect_signal(parent:Node2D, callback:Callable) -> void:
	if target_signal_node and target_signal:
		var signal_node = parent.get_node_or_null(target_signal_node)
		if signal_node and is_instance_valid(signal_node):
			var wrapper := func(_args = []):
				callback.call()
			if not signal_node.is_connected(target_signal, Callable(wrapper)):
				signal_node.connect(target_signal, Callable(wrapper))
