extends RefCounted
class_name SaveHelper

# ==============================================================================
# SaveManager
# ------------------------------------------------------------------------------
# Sistema genérico de gerenciamento de arquivos de save.
# Responsável por salvar e carregar dados do jogo em arquivos binários, com
# suporte opcional para:
#     - compressão
#     - criptografia AES-256 (modo ECB)
#     - múltiplos slots numerados
#
# O formato final do arquivo é:
#     JSON → UTF8 → (compressão opcional) → (criptografia opcional)
#
# O SaveManager não mantém estado interno. Toda chamada fornece o dicionário
# de dados completo a ser salvo. Ele também emite sinais indicando sucesso ou
# falha das operações.
#
# Este script é 100% compatível com Godot 4.x.
# ==============================================================================

const SAVE_DIR := "user://saves/"     # Diretório onde os arquivos de save são armazenados
const AES_KEY_SIZE := 32              # Tamanho da chave AES (256 bits)

# ------------------------------------------------------------------------------
# SINAIS
# ------------------------------------------------------------------------------
# save_completed(slot)    → Emitido após salvar um arquivo com sucesso
# load_completed(slot,data) → Emitido quando o arquivo foi carregado e decodificado
# save_failed(slot,reason)  → Emitido se algo impediu o salvamento
# load_failed(slot,reason)  → Emitido se o carregamento falhou por qualquer motivo
# ------------------------------------------------------------------------------

signal save_completed(slot: int)
signal load_completed(slot: int, data: Dictionary)
signal save_failed(slot: int, reason: String)
signal load_failed(slot: int, reason: String)

# ==============================================================================
# DIRETÓRIO DE SAVE
# ==============================================================================

# Garante que o diretório "user://saves/" existe antes de usar.
func _ensure_save_dir():
	if not DirAccess.dir_exists_absolute(SAVE_DIR):
		DirAccess.make_dir_recursive_absolute(SAVE_DIR)

# Monta o caminho completo do arquivo baseado no número do slot.
# Exemplo de saída: "user://saves/save_003.bin"
func _get_slot_path(slot: int) -> String:
	return "%s/save_%03d.bin" % [SAVE_DIR, slot]

# ==============================================================================
# CRIPTOGRAFIA AES–ECB
# ------------------------------------------------------------------------------
# Godot 4 fornece a classe AESContext, que suporta AES-256 e modo ECB.
# Este modo não utiliza IV e opera em blocos individuais.
# O SaveManager utiliza ECB apenas para simplicidade e compatibilidade.
# ==============================================================================

# Aplica criptografia AES-256-ECB aos dados.
# Entrada: bytes brutos e chave de qualquer tamanho.
# Saída: bytes criptografados.
func _encrypt_ecb(data: PackedByteArray, key: PackedByteArray) -> PackedByteArray:
	var aes := AESContext.new()

	# Garante que a chave possui exatamente 32 bytes.
	# Se for menor, será preenchida com zeros; se maior, será truncada.
	key.resize(AES_KEY_SIZE)
	
	# PKCS7 PADDING
	var padded_data := _pkcs7_pad(data, 16)

	aes.start(aes.MODE_ECB_ENCRYPT, key)
	var out := aes.update(padded_data)
	aes.finish()  # Em Godot 4, finish() não retorna dados

	return out

# Remove a criptografia AES-256-ECB dos dados.
func _decrypt_ecb(data: PackedByteArray, key: PackedByteArray) -> PackedByteArray:
	var aes := AESContext.new()

	key.resize(AES_KEY_SIZE)

	aes.start(aes.MODE_ECB_DECRYPT, key)
	var out := aes.update(data)
	aes.finish()

	return _pkcs7_unpad(out)


# ==============================================================================
# PKCS#7 Padding
# ------------------------------------------------------------------------------ 
# Utilizado para garantir que os dados possuam tamanho múltiplo do bloco AES.
# O padding adiciona N bytes ao final, cada um com valor N.
# ==============================================================================

# Aplica padding PKCS#7 ao array de bytes.
func _pkcs7_pad(data: PackedByteArray, block_size: int = 16) -> PackedByteArray:
	var pad_len := block_size - (data.size() % block_size)
	if pad_len == 0:
		pad_len = block_size  # bloco completo conforme PKCS#7
	
	var padded := data.duplicate()
	for i in pad_len:
		padded.append(pad_len)  # repete o valor pad_len
	
	return padded


# Remove padding PKCS#7, validando o valor informado.
func _pkcs7_unpad(data: PackedByteArray) -> PackedByteArray:
	if data.is_empty():
		return data
	
	var pad_len: int = data[-1]

	# padding inválido → retorna original
	if pad_len < 1 or pad_len > 16 or data.size() < pad_len:
		return data
	
	# validação completa dos bytes finais
	for i in range(pad_len):
		if data[data.size() - 1 - i] != pad_len:
			return data
	
	return data.slice(0, data.size() - pad_len)



# ==============================================================================
# SALVAR ARQUIVOS DE SAVE
# ==============================================================================

# Salva um dicionário contendo qualquer tipo de informação do jogo.
# O SaveManager NÃO armazena dados internamente; utiliza sempre o parâmetro `data`.
# Parâmetros:
#   slot      → número do slot onde será salvo
#   data      → dicionário contendo todos os dados do save
#   compress  → se verdadeiro, usa compressão
#   encrypt   → se verdadeiro, aplica criptografia AES
#   key       → chave de criptografia (obrigatória se encrypt=true)
func save_game(slot: int, data: Dictionary, compress := false, encrypt := false, key := ""):
	_ensure_save_dir()

	var path = _get_slot_path(slot)

	# Converte o dicionário em JSON identado (mais fácil de debugar)
	var json := JSON.stringify(data, "\t")

	# Converte para bytes UTF-8
	var bytes := json.to_utf8_buffer()
	var original_size = bytes.size()
	
	# Compressão opcional
	if compress:
		bytes = bytes.compress(FileAccess.COMPRESSION_GZIP)
	
	# Criptografia opcional
	if encrypt:
		if key == "":
			save_failed.emit(slot, "Chave inválida")
			return
		bytes = _encrypt_ecb(bytes, key.to_utf8_buffer())

	# Grava dados no arquivo
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		save_failed.emit(slot, "Falha ao abrir arquivo")
		return
	
	file.store_32(original_size)
	file.store_buffer(bytes)
	file.close()
	

	save_completed.emit(slot)

# ==============================================================================
# CARREGAR ARQUIVOS DE SAVE
# ==============================================================================

func load_game(slot: int, decompress := false, decrypt := false, key := "") -> Dictionary:
	var path = _get_slot_path(slot)

	if not FileAccess.file_exists(path):
		load_failed.emit(slot, "Arquivo não existe")
		return {}

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		load_failed.emit(slot, "Falha ao abrir arquivo")
		return {}
		
	var original_size = file.get_32()
	
	# Lê todo o arquivo como bytes binários
	var bytes := file.get_buffer(file.get_length())
	file.close()
	
	# Descriptografia opcional
	if decrypt:
		if key == "":
			load_failed.emit(slot, "Chave inválida")
			return {}
		bytes = _decrypt_ecb(bytes, key.to_utf8_buffer())

	# Descompressão opcional
	if decompress:
		# Usa o tamanho lido para a descompressão
		bytes = bytes.decompress(original_size, FileAccess.COMPRESSION_GZIP)
		
		# É CRUCIAL VERIFICAR SE FOI BEM-SUCEDIDO!
		if bytes.is_empty():
			load_failed.emit(slot, "Falha na descompressão (retornou vazio)")
			return {}
		
	# Converte para texto UTF-8 e depois para JSON
	var text := bytes.get_string_from_utf8()
	var parsed := JSON.parse_string(text)

	if parsed == null:
		load_failed.emit(slot, "JSON inválido")
		return {}

	load_completed.emit(slot, parsed)
	return parsed

# ==============================================================================
# UTILIDADES
# ==============================================================================

# Remove o arquivo de save do slot especificado
func delete_slot(slot: int):
	var path = _get_slot_path(slot)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)

# Retorna uma lista contendo nomes dos arquivos de save disponíveis
func list_slots() -> Array:
	_ensure_save_dir()

	var dir := DirAccess.open(SAVE_DIR)
	var out := []

	if dir:
		dir.list_dir_begin()
		var f = dir.get_next()
		while f != "":
			if f.ends_with(".bin"):
				out.append(f)
			f = dir.get_next()

	return out
