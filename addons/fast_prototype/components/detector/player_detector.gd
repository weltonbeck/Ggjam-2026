extends Area2D
class_name PlayerDetector

## Se verdadeiro, o detector dispara apenas uma vez
## e ignora entradas subsequentes do player.
@export var trigger_once: bool = false

@export_group("Interaction")
## Nome da ação de input usada para interação
## (ex: "interact", "ui_accept", "action")
@export var interaction_input_action: StringName = ""

## Flag interna para evitar múltiplos disparos
## quando o detector é configurado como "trigger_once".
var _triggered: bool = false

## Referência ao player atualmente dentro da área
## (null quando não há player presente)
var _player_inside: Node2D = null


## Emitido quando o player entra na área de detecção.
signal player_entered(player: Node2D)

## Emitido quando o player sai da área de detecção.
signal player_exited(player: Node2D)

## Emitido quando o player está dentro da área
## e pressiona a ação configurada.
signal player_interacted(player: Node2D)


# ------------------------------------------------------------------------------
# Lifecycle
# ------------------------------------------------------------------------------

func _ready() -> void:
	# Conecta sinais de entrada e saída de corpos físicos.
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	# Configura corretamente as camadas e máscaras de colisão
	set_collision_layers()


func _process(_delta: float) -> void:
	# Verifica interação apenas se houver um player dentro da área
	if _player_inside == null:
		return

	# Detecta input contextual (ex: apertar botão de interação)
	if interaction_input_action and InputMap.has_action(interaction_input_action) and Input.is_action_just_pressed(interaction_input_action):
		player_interacted.emit(_player_inside)


# ------------------------------------------------------------------------------
# Collision Configuration
# ------------------------------------------------------------------------------

## Configura as camadas e máscaras de colisão do detector.
## Este componente:
## - Não colide fisicamente
## - Apenas detecta a presença do player via sobreposição
func set_collision_layers() -> void:
	# Remove qualquer configuração herdada de colisão
	collision_layer = 0
	collision_mask = 0

	# Detecta exclusivamente entidades configuradas
	# na layer de colisão do player
	set_collision_mask_value(Globals.LAYER_PLAYER, true)


# ------------------------------------------------------------------------------
# Signal Callbacks
# ------------------------------------------------------------------------------

## Callback disparado quando um corpo entra na área.
func _on_body_entered(body: Node2D) -> void:
	if trigger_once and _triggered:
		return
		
	# Validação dupla:
	# - Pertencer ao grupo de player (flexível)
	# - Ser do tipo CharacterBehavior (segurança de tipo)
	if body.is_in_group(Globals.GROUP_PLAYER) and body is CharacterBehavior:
		_player_inside = body
		_triggered = true

		player_entered.emit(body)


## Callback disparado quando um corpo sai da área.
func _on_body_exited(body: Node2D) -> void:
	if _player_inside and body.is_in_group(Globals.GROUP_PLAYER) and body is CharacterBehavior:
		_player_inside = null
		player_exited.emit(body)
