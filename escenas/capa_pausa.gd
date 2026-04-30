extends CanvasLayer


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		visible = not visible
		get_tree().paused = visible
