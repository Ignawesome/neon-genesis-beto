extends Node2D


@export var velocidad: float = 100

var direccion: Vector2

func _ready() -> void:
	direccion = Vector2.RIGHT if randi() % 2 else Vector2.LEFT
	scale.x = direccion.x


func _physics_process(delta: float) -> void:
	if direccion.x > 0:
		position.x += velocidad * delta
	else:
		position.x -= velocidad * delta
