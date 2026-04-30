class_name Burbuja
extends Area2D

@export var velocidad := 100.0
@export var altura_maxima := -6000


# Suben un poquito cada frame
func _physics_process(delta: float):
	global_position.y -= velocidad * delta

	# Desaparece si sale de pantalla para evitar un memory leak
	if altura_maxima > global_position.y:
		queue_free()
	
