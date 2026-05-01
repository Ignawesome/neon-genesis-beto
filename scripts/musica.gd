extends Node

var reproductor: AudioStreamPlayer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	reproductor = AudioStreamPlayer.new()
	add_child(reproductor)

func reproducir_cancion(cancion: AudioStream) -> void:
	reproductor.stream = cancion
	reproductor.play()

func pausar() -> void:
	reproductor.stop()
