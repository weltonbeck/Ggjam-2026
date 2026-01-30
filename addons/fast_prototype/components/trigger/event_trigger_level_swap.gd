extends EventTriggerBase

## Cena que sera chamada
@export var packed_scene: PackedScene

## tempo de espera para ativar
@export var await_time:float = 0.2

func on_trigger_active() -> void:
	await get_tree().create_timer(await_time, false).timeout
	if packed_scene:
		SceneManager.change_scene(packed_scene)
