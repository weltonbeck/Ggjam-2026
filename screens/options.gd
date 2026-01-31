extends Control
@onready var music_slider: HSlider = $MarginContainer/Layout/Menu/MusicSlider
@onready var sound_slider: HSlider = $MarginContainer/Layout/Menu/SoundSlider


func _ready() -> void:
	music_slider.value = 1 #Carregar das configs
	sound_slider.value = 1


func _on_value_changed(_value: float, bus_name: String) -> void:
	var bus_index = AudioServer.get_bus_index(bus_name)
	AudioServer.set_bus_volume_db(
		bus_index,
		linear_to_db(_value)
		)
