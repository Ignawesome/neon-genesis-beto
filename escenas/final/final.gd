extends Control

@export var duracion_escena := 5.0

@export var _6: TextureRect
@export var _5: TextureRect
@export var _4: TextureRect
@export var _3: TextureRect
@export var _2: TextureRect
@export var _1: TextureRect

var escena_actual := 1
var en_transicion: bool = false

# 1. Declaramos el diccionario vacío acá arriba
var escenas: Dictionary[int, Control] = {}

func _ready() -> void:
	# 2. Lo llenamos acá, cuando Godot ya cargó el Inspector
	escenas = {
		1: _1,
		2: _2,
		3: _3,
		4: _4,
		5: _5,
		6: _6,
	}

func _input(event: InputEvent) -> void:
	if en_transicion:
		return
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("disparar"):
		siguiente_escena()

func siguiente_escena() -> void:
	if escena_actual > 5:
		await get_tree().create_timer(2).timeout
		get_tree().change_scene_to_file("res://escenas/menu/menu.tscn")
		return
		
	await transicion(escenas[escena_actual])
	escena_actual += 1

func transicion(nodo: Control) -> void:
	en_transicion = true
	# Siempre tenés que usar la función global create_tween().
	var tween := create_tween()
	tween.tween_property(nodo, "modulate", Color.TRANSPARENT, 1.0)
	await tween.finished
	en_transicion = false
