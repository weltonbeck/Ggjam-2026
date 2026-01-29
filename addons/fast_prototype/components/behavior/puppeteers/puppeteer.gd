extends Node
class_name Puppeteer

## ===========================================================
## Puppeteer
## -----------------------------------------------------------
## Responsável por assumir o controle de um CharacterBehavior,
## desativando os inputs normais do personagem e executando
## lógica externa (cutscenes, IA, scripts, eventos, etc).
## ===========================================================

## Indica se o Puppeteer está atualmente ativo.
## Quando ativo, o personagem perde o controle de input padrão.
@export var active: bool = false

## Referência ao personagem que será controlado.
@export var target: CharacterBehavior

signal started
signal finished

## ===========================================================
## Ciclo de vida
## ===========================================================

func _ready() -> void:
	if not Engine.is_editor_hint():
		# Garante que o personagem não esteja sob controle
		# do Puppeteer ao iniciar a cena.
		disable_target()
		if active:
			started.emit()
			start_puppetter()


func _process(delta: float) -> void:
	if not Engine.is_editor_hint():
		# Executa a lógica de controle apenas quando ativo
		# e com um alvo válido.
		if active and target:
			_puppeteer_process(delta)


## ===========================================================
## Controle de estado
## ===========================================================

## Desativa o controle de input do personagem alvo,
## impedindo ações manuais do jogador.
func disable_target() -> void:
	if active and target:
		target.deactivate_inputs_control()


## Ativa o Puppeteer e assume o controle do personagem.
## Os inputs normais do alvo são desabilitados.
func activate() -> void:
	active = true
	disable_target()
	started.emit()
	start_puppetter()


## Desativa o Puppeteer e devolve o controle ao personagem.
## Os inputs normais são reativados.
func deactivate() -> void:
	active = false
	finished.emit()
	if target:
		target.activate_inputs_control()


## ===========================================================
## Lógica de controle customizada
## ===========================================================

func start_puppetter() -> void:
	pass

## Método interno responsável pela lógica específica
## de controle do personagem (movimento forçado, animações,
## sequências de script, IA simples, etc).
##
## Deve ser sobrescrito ou expandido conforme a necessidade.
func _puppeteer_process(delta: float) -> void:
	pass
