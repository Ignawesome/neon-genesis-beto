class_name Jugador
extends CharacterBody2D

# ==============================================================================
# PROPIEDADES EXPORTADAS (Visible en el Inspector)
# ==============================================================================

# Movimiento
@export var velocidad_actual: float = 0.0 ## Velocidad horizontal/vertical base
@export var aceleración: float = 600.0
@export var velocidad_de_giro: float = 3.0
@export var friccion: float = 400.0
@export var velocidad_maxima := 500
@export var velocidad_maxima_reversa = 150.0

# Ataque
@export var fuerza_de_ataque := 1.0        ## Daño base de los misiles
@export var velocidad_de_ataque := 1.0     ## Frecuencia de disparo (ej: 1.0 por segundo)
@export var radio_de_ataque: float = 500.0 ## Distancia máxima para buscar enemigos
@export var duración_de_misil: float = 1.0 ## Segundos antes de que el misil desaparezca

# Defensa
@export var puntos_de_salud_maximos := 5         ## Vida máxima del personaje
@export var probabilidad_de_esquiva: float = 0.05  ## Probabilidad de no recibir daño (5%)
@export var material_daño: ShaderMaterial

# ==============================================================================
# REFERENCIAS Y PRECARGAS
# ==============================================================================
@onready var sonido_disparo: AudioStreamPlayer2D = $SonidoDisparo
@onready var sonido_dañado: AudioStreamPlayer2D = $SonidoDañado
@onready var sonido_level_up: AudioStreamPlayer2D = $SonidoLevelUp

@onready var timer_misil: Timer = $TimerMisil # ¡Debe existir este Timer en la escena!
@onready var sprite: Sprite2D = $Submarino


# ==============================================================================
# SISTEMA DE NIVELACIÓN Y ESTADÍSTICAS
# ==============================================================================

var nivel: int = 1
var experiencia_actual: float = 0.0
var experiencia_para_subir: float = 10.0 # Cantidad de XP necesaria para Nivel 2

# ==============================================================================
# VARIABLES Y SEÑALES
# ==============================================================================

var salud_actual: float: set = al_cambiar_de_salud

signal derrotado 

signal salud_cambiada(salud_nueva, salud_maxima)

signal nivel_subido(nuevo_nivel)

signal experiencia_ganada(cantidad)


# ==============================================================================
# FUNCIONES NATIVAS DE GODOT
# ==============================================================================


func _ready():
	# Inicializar la salud
	salud_actual = puntos_de_salud_maximos
	salud_cambiada.emit(salud_actual, puntos_de_salud_maximos)
	
	# Registrar al jugador como una variable global
	Globales.jugador = self
	
	# Conectar el timer del ataque
	timer_misil.timeout.connect(_on_timer_misil_timeout)


func _physics_process(delta: float) -> void:
	# 1. Obtener input del jugador (get_axis es más limpio para esto)
	# Devuelve -1 (izquierda/abajo), 1 (derecha/arriba) o 0 (nada)
	var giro = Input.get_axis("izquierda", "derecha")
	var avance = Input.get_axis("abajo", "arriba") 
	
	# 2. Aplicar rotación
	girar(giro, delta)
	
	# 3. Lógica de aceleración y frenado
	if avance > 0:
		acelerar(delta)
	elif avance < 0:
		retroceder(delta)
	else:
		desacelerar(delta)
	
	# 4. Convertir la velocidad escalar en un Vector2 direccional
	velocity = transform.x * velocidad_actual
	
	# 6. Mover el personaje
	move_and_slide()


# ==============================================================================
# SISTEMA DE MOVIMIENTO
# ==============================================================================

func acelerar(delta: float) -> void:
	velocidad_actual = move_toward(velocidad_actual, velocidad_maxima, aceleración * delta)
	
func desacelerar(delta: float) -> void:
	velocidad_actual = move_toward(velocidad_actual, 0.0, friccion * delta)

func retroceder(delta: float) -> void:
	velocidad_actual = move_toward(velocidad_actual, -velocidad_maxima_reversa, aceleración * delta)

func girar(direccion: float, delta: float) -> void:
	if direccion != 0:
		rotation += direccion * velocidad_de_giro * delta
		
# ==============================================================================
# SISTEMA DE MOVIMIENTO
# ==============================================================================

# La función move_toward() es mágica: acerca un número a otro de a pasos definidos,
# y evita pasarse del límite (hace el clamp automáticamente).

# ==============================================================================
# SISTEMA DE SALUD
# ==============================================================================

func al_cambiar_de_salud(nueva_salud: float) -> void:
	
	if nueva_salud > puntos_de_salud_maximos:
		nueva_salud = puntos_de_salud_maximos
	
	salud_actual = nueva_salud
	
	salud_cambiada.emit(salud_actual, puntos_de_salud_maximos)
	
	if salud_actual <= 0:
		morir()


func morir():
	derrotado.emit()
	get_tree().reload_current_scene.call_deferred()


func recibir_danio(cantidad_de_danio: float) -> void:
	if salud_actual <= 0:
		return
		
	# Lógica de Probabilidad de Esquiva
	if randf() < probabilidad_de_esquiva:
		# Feedback: Mostrar un mensaje de 'ESQUIVADO' (para implementar después)
		print("¡Esquivado!")
		return
		
	# Aplicar daño si no se esquiva
	salud_actual -= cantidad_de_danio
	sonido_dañado.pitch_scale = sonido_dañado.pitch_scale + randf_range(-0.2, 0.2)
	sonido_dañado.play()
	material = material_daño
	await get_tree().create_timer(0.25).timeout
	material = null
	
	# Aquí se puede agregar lógica de feedback visual (parpadeo)

# ==============================================================================
# SISTEMA DE PROGRESIÓN (XP y Nivelación)
# ==============================================================================

func ganar_experiencia(cantidad: float) -> void:
	experiencia_actual += cantidad
	experiencia_ganada.emit(cantidad)
	
	# Verificar si se sube de nivel
	if experiencia_actual >= experiencia_para_subir:
		subir_de_nivel()

func subir_de_nivel() -> void:
	# Ajustar XP restante y aumentar nivel
	experiencia_actual -= experiencia_para_subir
	nivel += 1
	sonido_level_up.play()
	
	# Aumentar la XP necesaria para el próximo nivel (ej: 10% más difícil)
	experiencia_para_subir *= 1.1 
	
	# Aumentar capacidades (el núcleo del juego!)
	puntos_de_salud_maximos += 1
	fuerza_de_ataque += 0.5
	velocidad_de_ataque *= 0.9
	timer_misil.wait_time = velocidad_de_ataque
	probabilidad_de_esquiva = min(probabilidad_de_esquiva + 0.05, 0.5) # Máximo 50% de esquiva
	
	# Curar al máximo y emitir señal de nivel subido
	salud_actual = puntos_de_salud_maximos
	nivel_subido.emit(nivel)
	print("¡Nivel subido a %d!" % nivel)

# ==============================================================================
# SISTEMA DE ATAQUE AUTOMÁTICO
# ==============================================================================

# Conectado a la señal 'timeout' del TimerAtaque
func _on_timer_misil_timeout():
	var enemigo_cercano: Enemigo = buscar_enemigo_cercano()
	
	if enemigo_cercano:
		# Calcular la dirección hacia el enemigo
		var direccion_de_disparo = global_position.direction_to(enemigo_cercano.global_position)
		lanzar_misil_a_direccion(direccion_de_disparo)

# Función principal para buscar el objetivo
func buscar_enemigo_cercano() -> Enemigo:
	var enemigos = get_tree().get_nodes_in_group("enemigos")
	var enemigo_mas_cercano: Enemigo = null
	var distancia_minima: float = radio_de_ataque * radio_de_ataque # Usamos distancia^2 para optimizar
	
	for enemigo in enemigos:
		# Calculamos la distancia al cuadrado (es más rápido que calcular la raíz cuadrada)
		var distancia_actual_cuadrada = global_position.distance_squared_to(enemigo.global_position)
		
		# Verificamos si es más cercano Y está dentro del radio de ataque
		if distancia_actual_cuadrada < distancia_minima:
			distancia_minima = distancia_actual_cuadrada
			enemigo_mas_cercano = enemigo
			
	return enemigo_mas_cercano

# Función para instanciar el proyectil y configurarlo
func lanzar_misil_a_direccion(direccion_de_disparo: Vector2) -> void:
	var nuevo_misil: Misil = Misil.crear_misil(duración_de_misil, fuerza_de_ataque)
	
	
	# 1. Posicionamiento: Lanzamos el misil desde el centro del jugador
	get_parent().add_child(nuevo_misil) # Lo añadimos al nodo principal (Mundo)
	nuevo_misil.global_position = global_position
	
	# 2. Configuración: Le pasamos la dirección y el daño
	nuevo_misil.direccion = direccion_de_disparo.normalized()
	nuevo_misil.danio_a_infligir = fuerza_de_ataque
	sonido_disparo.play()
	
	# Aquí podrías rotar el sprite del misil para que apunte a la dirección
	# nuevo_misil.rotation = direccion_de_disparo.angle()
