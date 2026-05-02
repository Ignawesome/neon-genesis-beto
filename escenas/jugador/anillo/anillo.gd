class_name Anillo
extends Area2D

const ANILLO = preload("uid://cwnt55x1lfkm")

signal anillo_creado
signal anillo_destruido

@onready var animation_player: AnimationPlayer = $AnimationPlayer

static func crear_anillo(padre: Node2D) -> Anillo:
	var anillo: Anillo = ANILLO.instantiate()
	padre.add_child(anillo)
	anillo.global_position = padre.global_position
	return anillo


func _ready() -> void:
	animation_player.play("expansion")
	animation_player.animation_finished.connect(anillo_destruido.emit)
	anillo_creado.emit()


func _on_area_entered(area: Area2D) -> void:
	if area is Misil:
		area.explotar()


func _on_body_entered(body: Node2D) -> void:
	if body is Enemigo:
		body.recibir_danio(Globales.jugador.fuerza_de_ataque)
