class_name Mundo
extends Node

@onready var contenedor_hp: HBoxContainer = %ContenedorHP

const RANURA_CORAZON = preload("uid://tnju06m5ruxw")

func _ready() -> void:
	Globales.jugador.salud_cambiada.connect(actualizar_hp)

func actualizar_hp(nueva_salud: int, _hp_maximo: int):
	for ranura_corazon: Node in contenedor_hp.get_children():
		ranura_corazon.get_child(0).hide()
	
	if contenedor_hp.get_children().size() < nueva_salud:
		agregar_nuevo_corazón()
	
	for punto_hp: int in nueva_salud:
		contenedor_hp.get_child(punto_hp).get_child(0).show()

func agregar_nuevo_corazón():
	contenedor_hp.add_child(RANURA_CORAZON.instantiate())
