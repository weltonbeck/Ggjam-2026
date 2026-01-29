extends EditorPlugin
class_name AudioConfigurePlugin

var buses = [
	"BGM",
	"SFX"
]

func create():
	var idx = AudioServer.get_bus_count()
	for bus in buses:
		# Criar BGM se não existir
		if not _bus_exists(bus):
			_add_bus(bus)
	

func remove():
	pass
	

func _add_bus(name: String):
	# adiciona um novo bus no final
	AudioServer.add_bus(AudioServer.get_bus_count())

	# agora pega o ÚLTIMO bus
	var last_idx := AudioServer.get_bus_count() - 1

	AudioServer.set_bus_name(last_idx, name)
	print("✅ Bus criado: ", name)
	
func _bus_exists(name: String) -> bool:
	for i in AudioServer.get_bus_count():
		if AudioServer.get_bus_name(i) == name:
			return true
	return false
