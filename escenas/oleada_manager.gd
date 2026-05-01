class_name OleadaManager
extends Node

@export var contenedor: ContenedorEnemigos

# Cargás tus escenas acá en el Inspector
@export var barco_ingles: PackedScene
@export var bache_mutante: PackedScene

# --- ESTRUCTURA DE LA OLEADA ---
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
	
	# DISEÑO DE NIVELES:
	# Parámetros: (Duración en segs, [Array de Enemigos permitidos], Tasa de spawn inicial)
	lista_oleadas.append(DatosOleada.new(30.0, [barco_ingles], 2.5)) 
	lista_oleadas.append(DatosOleada.new(45.0, [barco_ingles], 2.0))
	lista_oleadas.append(DatosOleada.new(60.0, [barco_ingles], 1.0)) # Oleada final hardcore
	
	iniciar_oleada(0)

func iniciar_oleada(indice: int) -> void:
	if indice >= lista_oleadas.size():
		contenedor.detener_spawns()
		print("¡GANASTE!")
		return
		
	indice_actual = indice
	var oleada = lista_oleadas[indice_actual]
	
	print("--- INICIANDO OLEADA ", indice_actual + 1, " ---")
	
	# Le pasamos la pelota al contenedor para que haga su magia
	contenedor.configurar_y_arrancar(oleada.pool_enemigos, oleada.frecuencia_inicial)
	
	# Arrancamos el reloj para la próxima oleada
	timer_oleada.start(oleada.duracion)

func siguiente_oleada() -> void:
	iniciar_oleada(indice_actual + 1)
