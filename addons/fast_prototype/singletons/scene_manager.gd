extends Node

# ================================================================
# SceneManager.gd
# ---------------------------------------------------------------
# Sistema centralizado de troca de cenas.
#
# ✔ Aceita tanto caminhos (.tscn) quanto PackedScenes
# ✔ Faz validação de cenas antes de trocar
# ✔ Controla estado para evitar trocas simultâneas
# ✔ Integração direta com AudioManager (fade-out opcional)
# ✔ Integração com CameraManager (desabilita durante troca)
# ✔ Permite reload da cena atual
# ---------------------------------------------------------------
# Uso:
#     SceneManager.change_scene("res://scenes/game.tscn")
#     SceneManager.reload_current_scene()
# ================================================================


# Caminho da cena atualmente carregada
var current_scene_path: String = ""

# Flag para impedir trocas simultâneas
var is_changing_scene: bool = false


# ================================================================
#  Troca de Cena Principal
# ---------------------------------------------------------------
# Aceita:
#     - String → caminho da cena
#     - PackedScene → cena já carregada
#
# Parâmetros:
#     new_scene    (String | PackedScene)
#     fade_audio   (bool) → controla se o áudio deve fazer fade-out
# ================================================================
func change_scene(new_scene: Variant, fade_audio: bool = true) -> void:
	# Impede chamadas duplicadas
	if is_changing_scene:
		push_warning("SceneManager: Já estou mudando de cena, pedido ignorado.")
		return
	
	var packed: PackedScene

	# -------------------------------
	# Se veio um caminho, validar
	# -------------------------------
	if typeof(new_scene) == TYPE_STRING:
		if not _validate_scene_path(new_scene):
			push_error("SceneManager: Caminho inválido ou cena inexistente: " + new_scene)
			return
		packed = load(new_scene)

	# -------------------------------
	# Se veio um PackedScene, aceitar
	# -------------------------------
	elif new_scene is PackedScene:
		packed = new_scene

	# -------------------------------
	# Qualquer outra coisa → inválido
	# -------------------------------
	else:
		push_warning("Tipo inválido em change_scene(): %s" % typeof(new_scene))
		return    
	
	is_changing_scene = true

	# ============================================================
	#  FADE-OUT DE ÁUDIO (Opcional)
	# ------------------------------------------------------------
	# Só faz fade se:
	#   - o parâmetro permitir
	#   - o AudioManager existir
	#   - a música realmente estiver tocando
	# ============================================================
	#if fade_audio and AudioManager and AudioManager.bgm_player.playing:
		#await AudioManager.fade_out_bgm()

	# ============================================================
	#  DESATIVA O CAMERA MANAGER DURANTE A TROCA
	# ------------------------------------------------------------
	# Isso impede que triggers de câmera executem enquanto
	# a nova cena está carregando (bugs comuns).
	# ============================================================
	if CameraManager:
		CameraManager.disable()

	# Guarda o novo caminho como atual
	current_scene_path = packed.resource_path

	# ============================================================
	#  Troca a cena de fato
	# ============================================================
	if packed and packed is PackedScene:
		get_tree().change_scene_to_packed(packed)
	else:
		push_error("SceneManager: Falha ao carregar a cena: " + str(new_scene))

	# Finaliza estado de transição
	is_changing_scene = false

	# ============================================================
	#  REATIVA O CAMERA MANAGER APÓS A TROCA
	# ------------------------------------------------------------
	# Agora sim, triggers e câmeras podem funcionar normalmente.
	# ============================================================
	if CameraManager:
		CameraManager.enable()



# ================================================================
#  Recarrega a cena atual
# ---------------------------------------------------------------
# Caso não exista current_scene_path → mensagem de aviso
# ================================================================
func reload_current_scene() -> void:
	if current_scene_path == "":
		push_warning("SceneManager: Nenhuma cena atual registrada, não posso recarregar.")
		return

	change_scene(current_scene_path)


# ================================================================
#  Validador de Caminho de Cena
# ---------------------------------------------------------------
# Retorna true somente se:
#   - não for string vazia
#   - terminar com .tscn
#   - arquivo realmente existir
# ================================================================
func _validate_scene_path(path: String) -> bool:
	return path != "" and path.ends_with(".tscn") and FileAccess.file_exists(path)
