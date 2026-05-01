class_name ContenedorEnemigos
extends Node2D

@export var enemigos: Array[PackedScene]

@export var timer_spawn_enemigo: Timer
@export var timer_tasa_enemigos: Timer

@export var b_aumentar_frecuencia_enemigos := true
@export var tiempo_aumento_enemigos := 5
@export var tiempo_entre_enemigos := 3.0


func _ready() -> void:
	timer_spawn_enemigo.timeout.connect(spawnear_enemigo)
	timer_tasa_enemigos.timeout.connect(aumentar_frecuencia_enemigos)


# --- FUNCIONES PARA EL MANAGER DE OLEADA ---

func configurar_y_arrancar(nuevos_enemigos: Array[PackedScene], tasa_inicial: float):
	# Actualizamos los datos para la nueva oleada
	enemigos = nuevos_enemigos
	tiempo_entre_enemigos = tasa_inicial
	
	# Reiniciamos los timers
	timer_spawn_enemigo.wait_time = tiempo_entre_enemigos
	timer_spawn_enemigo.start()
	
	timer_tasa_enemigos.start(tiempo_aumento_enemigos)
	print("Arrancó nueva oleada. Tasa inicial: ", tasa_inicial)


func detener_spawns():
	timer_spawn_enemigo.stop()
	timer_tasa_enemigos.stop()


func empezar_spawnear_enemigos(durante: float):
	timer_tasa_enemigos.start(durante)
	timer_tasa_enemigos.timeout.connect(aumentar_frecuencia_enemigos)
	print("Empezó a spawnear enemigos")

func aumentar_frecuencia_enemigos():
	if not b_aumentar_frecuencia_enemigos:
		return
	tiempo_entre_enemigos = clamp(tiempo_entre_enemigos * 0.9, 0.2, 5)
	timer_spawn_enemigo.wait_time = tiempo_entre_enemigos
	timer_spawn_enemigo.start()
	print("Ahora la frecuencia de enemigos es %s" % tiempo_entre_enemigos)

func spawnear_enemigo():
	var escena_enemigo : PackedScene = enemigos.pick_random()
	var nodo_enemigo : Enemigo = escena_enemigo.instantiate()
	add_child(nodo_enemigo)
	nodo_enemigo.objetivo = Globales.jugador
	nodo_enemigo.global_position = get_posicion_al_azar()


func get_posicion_al_azar():
	var direccion_al_azar: Vector2 = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
	var posicion_jugador: Vector2 = Globales.jugador.global_position
	var distancia: float = randf_range(500, 1000)
	
	var posicion: Vector2 = posicion_jugador + direccion_al_azar * distancia
	return posicion
