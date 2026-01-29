extends RefCounted
class_name NodetHelper

## ------------------------------------------------------
## Retorna todos os node com uma class
## ------------------------------------------------------
static func get_all_of_type_by_classname(node: Node, target_class: Variant) -> Array:
	var found = []
	for child in node.get_children():
		if is_instance_of(child, target_class):
			found.append(child)
	return found
	

## ------------------------------------------------------
## Retorna o primeiro node com uma class
## ------------------------------------------------------
static func get_first_of_type_by_classname(node: Node, target_class: Variant) -> Node:
	var found = get_all_of_type_by_classname(node, target_class)
	if found.size() > 0:
		return found[0] 
	else:
		return  null

## ------------------------------------------------------
## Retorna o ultimo node com uma class
## ------------------------------------------------------
static func get_last_of_type_by_classname(node: Node, target_class: Variant) -> Node:
	var found = get_all_of_type_by_classname(node, target_class)
	if found.size() > 0:
		return found[-1] 
	else:
		return  null
