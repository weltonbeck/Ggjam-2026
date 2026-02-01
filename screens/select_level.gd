extends Control

@onready var mask_button_1: TextureButton = $MaskButton1
@onready var mask_button_2: TextureButton = $MaskButton2
@onready var mask_button_3: TextureButton = $MaskButton3
@onready var mask_button_4: TextureButton = $MaskButton4

const MASK_1_3 = preload("res://assets/hud/mask1-3.png")
const MASK_2_3 = preload("res://assets/hud/mask2-3.png")
const MASK_3_3 = preload("res://assets/hud/mask3-3.png")
const MASK_4_3 = preload("res://assets/hud/mask4-3.png")

signal all_masks

func _ready() -> void:
	var collected = 0
	
	if  GameStateManager.has_state("masks.fogo"):
		collected += 1
		mask_button_1.disabled = true
		mask_button_1.mouse_default_cursor_shape = Control.CURSOR_ARROW
		mask_button_1.texture_normal = MASK_1_3
	if GameStateManager.has_state("masks.tengu"):
		collected += 1
		mask_button_2.disabled = true
		mask_button_2.mouse_default_cursor_shape = Control.CURSOR_ARROW
		mask_button_2.texture_normal = MASK_2_3
	if GameStateManager.has_state("masks.medusa"):
		collected += 1
		mask_button_4.disabled = true
		mask_button_4.mouse_default_cursor_shape = Control.CURSOR_ARROW
		mask_button_4.texture_normal = MASK_3_3	
	if GameStateManager.has_state("masks.cavaleiro"):
		collected += 1
		mask_button_3.disabled = true
		mask_button_3.mouse_default_cursor_shape = Control.CURSOR_ARROW
		mask_button_3.texture_normal = MASK_4_3
	
	if collected >= 4:
		all_masks.emit()
