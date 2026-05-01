extends Control

static var cinematica_actual := 1
var cinematica_path := "res://escenas/menu/cinematica_%s.tscn"

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		_on_continuar_pressed()

func _on_continuar_pressed() -> void:
	cinematica_actual += 1
	if cinematica_actual > 6:
		get_tree().change_scene_to_file("res://escenas/mundo.tscn")
	else:
		get_tree().change_scene_to_file(cinematica_path % str(cinematica_actual))
