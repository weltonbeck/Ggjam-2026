@tool
class_name Block
extends StaticBody2D

enum STATES {DEFAULT,HITED}

@export var state:STATES = STATES.DEFAULT: ## estado do bloco
	set = change_state

## Se true, o block será executado apenas uma vez
@export var hit_once: bool = true

@export_group("Animation After Hit")
@export var animation_tree:AnimationTree
@export var animation_name:String
@export var animation_blend_param: String

@export_category("Audio")
@export var sound:AudioStreamPlayer ## barulho ao ser acertado

signal hited(direction: Vector2, transmit_limit:int) # foi atingido

var collectables: Array[Collectable]

func _ready() -> void:
	if not Engine.is_editor_hint():
		add_to_group(Globals.GROUP_BLOCK)
		parse_childrens_collectables()
	
func parse_childrens_collectables() -> void:
	if not Engine.is_editor_hint():
		collectables.clear()
		if get_child_count() > 0:
			var childrens_collectables = NodetHelper.get_all_of_type_by_classname(self, Collectable)
			if childrens_collectables.size() > 0:
				for collectable in childrens_collectables:
					var _child_scene = collectable.duplicate()
					collectables.append(_child_scene)
					collectable.queue_free()

func instanciate_collectables(direction: Vector2 = Vector2.UP) -> void:
	if collectables.size() > 0:
		for collectable in collectables:
			get_tree().root.add_child(collectable)
			collectable.global_position = global_position
			collectable.block_unpack(global_position,direction)

func change_state(_state:STATES) -> void:
	state = _state
	if Engine.is_editor_hint():
		if _state == STATES.HITED:
			set_hit_animation(Vector2.UP)
		else:
			if animation_tree:
				animation_tree.active = false
				animation_tree.active = true

func is_hitable() -> bool:
	return not state == STATES.HITED

func block_hit(direction: Vector2 = Vector2.UP, _transmit_limit: int = -1) -> void:
	hited.emit(direction, _transmit_limit)
	instanciate_collectables(direction)
	
	if hit_once:
		state = STATES.HITED
	
	set_hit_animation(direction)
	
	if sound:
		sound.play()

func set_hit_animation(direction:Vector2) -> void:
	if animation_tree:
		if animation_name:
			animation_tree_travel(animation_tree, animation_name)
		
		if animation_blend_param:
			set_animation_tree_blend_param(animation_tree,animation_blend_param, direction)

# Verifica a existência do estado e realiza o travel.
func animation_tree_travel(_animation_tree:AnimationTree, _animation_name: String, _playback_path: String = "parameters/playback") -> void:
	if  not _animation_tree or not is_instance_valid(_animation_tree) or not _animation_tree.is_inside_tree() or not _animation_name or not _playback_path or  not _animation_tree.get(_playback_path): 
		return
	var state_machine: AnimationNodeStateMachine = _animation_tree.tree_root
	var playback_control  = _animation_tree.get(_playback_path)
	var current_animation = playback_control .get_current_node()
	
	if state_machine.has_transition(current_animation, _animation_name):
		# Acessa o parâmetro usando a sintaxe de ponto e chama travel().
		playback_control.travel(_animation_name)

func set_animation_tree_blend_param(_animation_tree:AnimationTree, _param:String, _blend_2d_value:Vector2 = Vector2.ZERO):
	if not _animation_tree or not is_instance_valid(_animation_tree) or not _animation_tree.is_inside_tree() or not _param:
		return
		
	# Pega a lista completa de propriedades do AnimationTree
	var props = _animation_tree.get_property_list()

	var found_type: int = -1

	for p in props:
		if p.name == _param:
			found_type = p.type
			break

	if found_type == -1:
		# Propriedade não existe
		return
	
	# Define o valor de acordo com o tipo real da propriedade
	if found_type == TYPE_VECTOR2:
		_animation_tree.set(_param, _blend_2d_value)
