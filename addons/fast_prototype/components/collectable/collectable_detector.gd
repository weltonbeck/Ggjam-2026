extends Area2D
class_name CollectorComponent


## Emitido quando um coletável válido é detectado.
## Útil para HUD, FX, estatísticas ou lógica de gameplay.
signal collectable_detected(collectable: Collectable)


func _ready() -> void:
	# Conecta automaticamente o sinal de entrada de áreas.
	# Sempre que uma Area2D entrar neste coletor,
	# o método _on_area_entered será chamado.
	area_entered.connect(_on_area_entered)

	# Configura corretamente layers e masks do coletor
	set_collision_layers()


## Configura as camadas e máscaras de colisão do coletor.
## Este componente:
## - Não colide fisicamente
## - Apenas detecta sobreposição de coletáveis
func set_collision_layers() -> void:
	# Remove qualquer layer/mask padrão
	collision_layer = 0
	collision_mask = 0

	# Habilita apenas a máscara de coletáveis,
	# garantindo que o coletor só detecte esse tipo de objeto
	set_collision_mask_value(Globals.LAYER_COLLECTABLE, true)


## Callback disparado sempre que uma Area2D entra neste coletor.
## Responsável por validar se a área é um coletável
## e acionar a lógica de coleta.
func _on_area_entered(area: Area2D) -> void:
	# Verifica se:
	# - Pertence ao grupo de coletáveis (flexível)
	# - É do tipo Collectable (segurança de tipo)
	if area.is_in_group(Globals.GROUP_COLLECTABLE) and area is Collectable:
		emit_signal("collectable_detected", area)
		area.collect()
