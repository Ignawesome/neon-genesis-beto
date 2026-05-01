extends Control

const HIMNO = preload("uid://d24ubun81taa4")

func _ready()-> void:
	Musica.reproducir_cancion(HIMNO)

func _on_jugar_pressed() -> void:
	get_tree().change_scene_to_file("res://escenas/menu/cinematica_1.tscn")
