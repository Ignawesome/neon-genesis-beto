class_name OrbeDrop
extends Area2D

@export var cantidad_de_experiencia := 1.0
@export var cantidad_de_hp := 1.0

@onready var sonido_pickup: AudioStreamPlayer2D = $SonidoPickup

const ORBE_XP_ESCENA = preload("uid://bkmeox5n8r0w")
const ORBE_HP_ESCENA = preload("uid://bl3kjd4s4bdak")


static func crear_orbe_xp(cantidad_xp: float = 0.0):
	var orbe_nodo: OrbeDrop = ORBE_XP_ESCENA.instantiate()
	orbe_nodo.cantidad_de_experiencia = cantidad_xp
	orbe_nodo.cantidad_de_hp = 0
	return orbe_nodo


static func crear_orbe_hp():
	var orbe_nodo: OrbeDrop = ORBE_HP_ESCENA.instantiate()
	orbe_nodo.cantidad_de_experiencia = 0
	orbe_nodo.cantidad_de_hp = 1
	return orbe_nodo


func _on_body_entered(body: Node2D) -> void:
	if body is Jugador:
		body.ganar_experiencia(cantidad_de_experiencia)
		body.salud_actual += cantidad_de_hp
		sonido_pickup.play()
		hide()
		await sonido_pickup.finished
		queue_free()
