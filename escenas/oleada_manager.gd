class_name OleadaManager
extends Node

@export var contenedor: ContenedorEnemigos

@export var barco_ingles: PackedScene
@export var moto_espacial: PackedScene

var dificultad: int = 1

class DatosOleada:
	var duracion: float
	var pool_enemigos: Array[PackedScene]
	var frecuencia_inicial: float
	
	func _init(d: float, pool: Array[PackedScene], freq: float):
		duracion = d
		pool_enemigos = pool
		frecuencia_inicial = freq

var lista_oleadas: Array[DatosOleada] = []
var indice_actual: int = 0
var timer_oleada := Timer.new()

func _ready() -> void:
	add_child(timer_oleada)
	timer_oleada.one_shot = true
	timer_oleada.timeout.connect(siguiente_oleada)
	
	lista_oleadas.append(DatosOleada.new(30.0, [moto_espacial], 2.5)) 
	lista_oleadas.append(DatosOleada.new(45.0, [barco_ingles], 2.0))
	lista_oleadas.append(DatosOleada.new(60.0, [barco_ingles], 1.0)) 
	
	iniciar_oleada(0)

func iniciar_oleada(indice: int) -> void:
	# Como ahora aseguramos que el índice nunca se pase, 
	# borramos el bloque de "¡GANASTE!" para que sea infinito.
	
	indice_actual = indice
	var oleada = lista_oleadas[indice_actual]
	
	print("--- INICIANDO OLEADA ", indice_actual + 1, " (Dificultad: ", dificultad, ") ---")
	
	contenedor.configurar_y_arrancar(oleada.pool_enemigos, oleada.frecuencia_inicial, dificultad)
	
	timer_oleada.start(oleada.duracion)

func siguiente_oleada() -> void:
	# Subimos la dificultad si acabamos de terminar la última oleada del array.
	# (size es 3, así que size - 1 es 2, que equivale a la Oleada 3).
	if indice_actual == lista_oleadas.size() - 1:
		dificultad += 1
		print("¡CUIDADO! Sube la dificultad a %s" % dificultad)
		
	# El operador módulo (%) hace que si el número llega al tamaño de la lista (3), 
	# vuelva a empezar desde 0 automáticamente.
	var proximo_indice = (indice_actual + 1) % lista_oleadas.size()
	
	iniciar_oleada(proximo_indice)
