extends Node

# ================================================================
# AudioManager.gd
# ---------------------------------------------------------------
# Sistema global de controle da música de fundo (BGM).
#
# Características principais:
#   - Crossfade suave entre músicas
#   - Fade-out independente para troca de cena
#   - Recuperação inteligente da música atual (não reinicia repetidas)
#   - Previne conflitos quando múltiplos fades são requisitados
#
# Uso típico:
#     AudioManager.play_bgm("res://musics/theme.ogg")
#     AudioManager.fade_out_bgm()
#     AudioManager.stop_bgm()
# ================================================================


# Players usados:
#   - bgm_player: reproduz a música ativa
#   - bgm_fade_player: usado apenas para fazer crossfade
var bgm_player: AudioStreamPlayer
var bgm_fade_player: AudioStreamPlayer

# Caminho da música atualmente tocando.
var current_bgm_path := ""

# Duração padrão do crossfade entre músicas.
var fade_speed := 1.5

# Indica se um crossfade está em andamento.
var is_fading := false

# Tween responsável por animar volumes. É sempre recriado quando necessário.
var tween: Tween



# ================================================================
# Inicialização
# ---------------------------------------------------------------
# Cria internamente os players, configura o bus e define volumes
# padrão. Este nó deve existir apenas uma vez no projeto.
# ================================================================
func _ready():
	bgm_player = AudioStreamPlayer.new()
	bgm_fade_player = AudioStreamPlayer.new()

	add_child(bgm_player)
	add_child(bgm_fade_player)

	bgm_player.bus = "BGM"
	bgm_fade_player.bus = "BGM"

	bgm_player.volume_db = 0
	bgm_fade_player.volume_db = -50



# ================================================================
# Tocar uma música de fundo
# ---------------------------------------------------------------
# path: caminho da música
# fade: se verdadeiro, realiza crossfade; senão troca diretamente
#
# Regras importantes:
#   - Se a mesma música for pedida, não reinicia; apenas volta a tocar.
#   - Se a música não for encontrada, um erro é exibido.
# ================================================================
func play_bgm(path: Variant, fade:bool = true, volume_percent: float = 100.0):
	if not path is AudioStream and not path is String:
		push_error("AudioManager: Tipo inválido")
		return
	
	if path is AudioStream:
		path = path.resource_path
		
	# Evita reiniciar a mesma música
	if path == "" or path == current_bgm_path:
		if not bgm_player.playing:
			bgm_player.play()
		return

	# Carrega o novo stream
	var new_stream = load(path)
	if new_stream == null:
		push_error("AudioManager: Música não encontrada: " + path)
		return

	current_bgm_path = path
	
	
	# Troca instantânea caso o fade esteja desativado
	if not fade:
		bgm_player.stream = new_stream
		set_bgm_volume_percent(volume_percent)
		bgm_player.play()
		return

	# CONVERTE o percentual desejado para o DB final.
	var final_db = _percent_to_db(volume_percent)
	
	# Usa o sistema de crossfade
	crossfade_to_stream(new_stream, final_db)



# ================================================================
# Crossfade entre músicas
# ---------------------------------------------------------------
# Faz a transição gradual entre a música atual e a música nova.
# A música antiga é reproduzida no bgm_player, e a nova no
# bgm_fade_player. Após o fade, a nova música assume como player
# principal.
# ================================================================
func crossfade_to_stream(new_stream: AudioStream, final_db: float = 0):
	# Cancela fade anterior, se existir
	if is_fading and tween:
		tween.kill()

	is_fading = true

	# Prepara o player de fade
	bgm_fade_player.stream = new_stream
	bgm_fade_player.volume_db = -50
	bgm_fade_player.play()

	# Cria tween de transição
	tween = create_tween()
	tween.set_parallel()

	# Volume da música antiga desce
	tween.tween_property(bgm_player, "volume_db", -50, fade_speed)
	# Volume da música nova sobe
	tween.tween_property(bgm_fade_player, "volume_db", final_db, fade_speed)
	# Aguarda finalização da animação
	await tween.finished

	# Conclui troca dos players
	bgm_player.stop()
	bgm_player.stream = new_stream
	bgm_player.volume_db = final_db
	bgm_player.play()

	bgm_fade_player.stop()
	is_fading = false



# ================================================================
# Fade-out total da música atual
# ---------------------------------------------------------------
# Reduz o volume gradualmente até -50 dB e então para totalmente.
# Usado principalmente antes de trocar de cena.
# ================================================================
func fade_out_bgm(time := 1.2):
	if tween:
		tween.kill()

	tween = create_tween()
	tween.tween_property(bgm_player, "volume_db", -50, time)

	await tween.finished

	bgm_player.stop()



# ================================================================
# Finalizar música imediatamente
# ---------------------------------------------------------------
# Cancela qualquer tween e para ambos players.
# ================================================================
func stop_bgm():
	if tween:
		tween.kill()
	bgm_player.stop()
	bgm_fade_player.stop()



# ================================================================
# Ajuste direto de volume
# ================================================================
func set_bgm_volume(db: float):
	bgm_player.volume_db = db



# ================================================================
# Consulta se uma música está tocando no player principal
# ================================================================
func is_bgm_playing() -> bool:
	return bgm_player.playing

# ================================================================
# Converte 0–100 para decibéis (-80 a 0)
# ================================================================
func _percent_to_db(percent: float) -> float:
	percent = clamp(percent, 0.0, 100.0)
	if percent <= 0.01:
		return -80.0
	return lerp(-80.0, 0.0, percent / 100.0)


# ================================================================
# Ajusta o volume do BGM usando percent (0–100)
# ================================================================
func set_bgm_volume_percent(percent: float):
	bgm_player.volume_db = _percent_to_db(percent)
