extends Area2D


@export var jugador: Jugador
@export var velocidad: float = 3.0

var objetos: Array[Node2D]


func _physics_process(delta: float) -> void:
	if not objetos.is_empty():
		for objeto: Node2D in objetos:
			objeto.global_position = lerp(objeto.global_position, self.global_position, delta * velocidad)


func _on_area_entered(area: Area2D) -> void:
	if area is OrbeDrop:
		objetos.append(area)
		area.tree_exited.connect(func(): objetos.erase(area))
