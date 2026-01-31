extends CanvasLayer

@export_category("Heart")
@export var heart_texture_black: Texture
@export var heart_texture_red: Texture
@export var heart_node: TextureRect
@export var hearts_container: Control
@export_placeholder("player") var game_state_heart_prefix: String = "player"

@export_category("Coins")
@export var coins_label: Label
@export_placeholder("collectables.key") var game_state_coin_key: String = "collectables.coin"

var max_hearts: int = 0
var curent_hearts: int = 0

var coins: int = 0

func _ready() -> void:
	render_hearts()
	GameStateManager.state_changed.connect(_on_state_changed)

func _on_state_changed(key:String,value) -> void:
	if key == game_state_heart_prefix + ".life":
		curent_hearts = int(value)
		render_hearts()
	elif key == game_state_heart_prefix + ".max_life":
		max_hearts = int(value)
		render_hearts()
	elif key == game_state_coin_key:
		coins = int(value)
		render_coins()

func render_hearts() -> void:
	if heart_texture_black and heart_texture_red and hearts_container and heart_node: 
	
		heart_node.hide()
		
		# limpa corações antigos (menos o template)
		for child in hearts_container.get_children():
			if child != heart_node:
				child.queue_free()

		# cria os corações
		for i in range(max_hearts):
			var heart := heart_node.duplicate()
			heart.show()

			if i < curent_hearts:
				heart.texture = heart_texture_red
			else:
				heart.texture = heart_texture_black
			hearts_container.add_child(heart)

func render_coins() -> void:
	if coins_label:
		coins_label.text = str(coins).pad_zeros(4)
