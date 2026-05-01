extends Control


func _on_continuar_pressed() -> void:
	get_tree().change_scene_to_file("res://escenas/mundo.tscn")
