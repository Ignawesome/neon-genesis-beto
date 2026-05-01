class_name Jugador
extends CharacterBody2D

signal derrotado 
signal salud_cambiada(salud_nueva, salud_maxima)
signal nivel_subido(nuevo_nivel)
signal experiencia_ganada(cantidad)

# ==============================================================================
# PROPIEDADES EXPORTADAS (Visible en el Inspector)
# ==============================================================================

# Movimiento
var velocidad_actual: float = 0.0: set = al_cambiar_velocidad ## Velocidad horizontal/vertical basev
var muriendo: bool = false

@export var aceleración: float = 600.0
@export var velocidad_de_giro: float = 3.0
@export var friccion: float = 400.0
@export var velocidad_maxima := 500
@export var velocidad_maxima_reversa = 150.0

# Ataque
@export var fuerza_de_ataque := 1.0        ## Daño base de los misiles
@export var misil_cooldown := 1.0     ## Frecuencia de disparo (ej: 1.0 por segundo)
@export var radio_de_ataque: float = 500.0 ## Distancia máxima para buscar enemigos
@export var duración_de_misil: float = 1.0 ## Segundos antes de que el misil desaparezca
@export var fuerza_de_choque: float = 1.0
@export var knockback_impacto: float = 500.0

# Defensa
@export var puntos_de_salud_maximos := 5         ## Vida máxima del personaje
@export var probabilidad_de_esquiva: float = 0.05  ## Probabilidad de no recibir daño (5%)
@export var material_daño: ShaderMaterial
@export var duracion_invulnerabilidad: float = 1.0

# ==============================================================================
# REFERENCIAS Y PRECARGAS
# ==============================================================================
@export var sonido_disparo: AudioStreamPlayer2D
@export var sonido_level_up: AudioStreamPlayer2D
@export var sonido_dañado: AudioStreamPlayer2D
@export var sonido_explosion: AudioStreamPlayer2D

@export var collision_shape_2d: CollisionShape2D

@export var timer_misil: Timer
@export var sprite_normal: Sprite2D
@export var sprite_roto: Sprite2D
@export var next_lvl_bar: ProgressBar
@export var animation_player: AnimationPlayer

@export var motor_1: CPUParticles2D
@export var motor_2: CPUParticles2D

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
var puede_atacar: bool = true
var puede_esquivar: bool = true
var puede_activar_anillo: bool = true
var invulnerable: bool = false



# ==============================================================================
# FUNCIONES NATIVAS DE GODOT
# ==============================================================================


func _ready():
	sprite_normal.show()
	sprite_roto.hide()
	# Inicializar la salud
	salud_actual = puntos_de_salud_maximos
	salud_cambiada.emit(salud_actual, puntos_de_salud_maximos)
	
	next_lvl_bar.value = experiencia_actual
	next_lvl_bar.max_value = experiencia_para_subir
	
	# Registrar al jugador como una variable global
	Globales.jugador = self
	
	# Conectar el timer del ataquewa
	timer_misil.timeout.connect(_on_timer_misil_timeout)
	timer_misil.wait_time = misil_cooldown


func _physics_process(delta: float) -> void:
	if muriendo:
		return
	if Input.is_action_pressed("disparar") and puede_atacar:
		puede_atacar = false
		var direccion_de_disparo := global_position.direction_to(get_global_mouse_position())
		lanzar_misil_a_direccion(direccion_de_disparo)
	if Input.is_action_pressed("esquivar") and puede_esquivar:
		esquivar()
	if Input.is_action_pressed("ulti") and puede_activar_anillo:
		activar_anillo()
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

func esquivar() -> void:
	invulnerable = true
	puede_esquivar = false
	fuerza_de_choque *= 3.0
	animation_player.play("esquivar")
	get_tree().create_timer(1.0).timeout.connect(
		func():
			invulnerable = false
			puede_esquivar = true
			animation_player.play("RESET")
			fuerza_de_choque /= 3.0
	)


func activar_anillo():
	puede_activar_anillo = false
	var anillo: Anillo = Anillo.crear_anillo(self)
	
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
	muriendo = true
	collision_shape_2d.disabled = true
	sprite_normal.hide()
	sprite_roto.show()
	
	animation_player.play("explotar")
	await animation_player.animation_finished
	derrotado.emit()
	
	await get_tree().create_timer(2).timeout
	get_tree().reload_current_scene.call_deferred()


func recibir_danio(cantidad_de_danio: float) -> void:
	if salud_actual <= 0 or invulnerable:
		return
		
	# Lógica de Probabilidad de Esquiva
	if randf() < probabilidad_de_esquiva:
		# Feedback: Mostrar un mensaje de 'ESQUIVADO' (para implementar después)
		esquivar()
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
	activar_invulnerabilidad(duracion_invulnerabilidad)
	

func activar_invulnerabilidad(duracion: float) -> void:
	animation_player.play("invulnerabilidad")
	invulnerable = true
	get_tree().create_timer(duracion).timeout.connect(
		func():
			invulnerable = false
			animation_player.play("RESET")
	)

# ==============================================================================
# SISTEMA DE PROGRESIÓN (XP y Nivelación)
# ==============================================================================

func ganar_experiencia(cantidad: float) -> void:
	experiencia_actual += cantidad
	experiencia_ganada.emit(cantidad)
	
	# Verificar si se sube de nivel
	if experiencia_actual >= experiencia_para_subir:
		subir_de_nivel()
	
	next_lvl_bar.value = experiencia_actual


func subir_de_nivel() -> void:
	puede_activar_anillo = true
	# Ajustar XP restante y aumentar nivel
	experiencia_actual -= experiencia_para_subir
	nivel += 1
	sonido_level_up.play()
	
	# Aumentar la XP necesaria para el próximo nivel (ej: 10% más difícil)
	experiencia_para_subir *= 1.1 
	next_lvl_bar.max_value = experiencia_para_subir
	
	# Aumentar capacidades (el núcleo del juego!)
	puntos_de_salud_maximos += 1
	fuerza_de_ataque += 0.5
	misil_cooldown *= 0.9
	timer_misil.wait_time = misil_cooldown
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
	puede_atacar = true
	#var enemigo_cercano: Enemigo = buscar_enemigo_cercano()
	#
	#if enemigo_cercano:
		## Calcular la dirección hacia el enemigo
		#var direccion_de_disparo = global_position.direction_to(enemigo_cercano.global_position)
		#lanzar_misil_a_direccion(direccion_de_disparo)

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
	nuevo_misil.rotation = nuevo_misil.direccion.angle()
	nuevo_misil.velocidad_heredada = velocity
	
	puede_atacar = false
	sonido_disparo.play()
	
	# Aquí podrías rotar el sprite del misil para que apunte a la dirección
	# nuevo_misil.rotation = direccion_de_disparo.angle()


func al_cambiar_velocidad(nueva_velocidad: float) -> void:
	if not is_node_ready():
		await ready
		
	velocidad_actual = nueva_velocidad
	
	# Usamos clampf() por seguridad, para asegurar que la proporción NUNCA 
	# se pase de 1.0 o baje de 0.0, incluso si el colectivo recibe un empuje extra.
	var proporcion: float = clampf(velocidad_actual / velocidad_maxima, 0.0, 1.0)
	
	var min_velocity_at_max_speed := 160.0
	var max_velocity_at_max_speed := 440.0
	
	# Calculamos los valores usando lerp(). 
	# Cuando proporcion es 0.0, devuelve 1.0. Cuando es 1.0, devuelve la velocidad máxima.
	var calc_min = lerp(1.0, min_velocity_at_max_speed, proporcion)
	var calc_max = lerp(1.0, max_velocity_at_max_speed, proporcion)
	
	# Aplicamos los cálculos a los motores
	motor_1.initial_velocity_min = calc_min
	motor_1.initial_velocity_max = calc_max
	
	motor_2.initial_velocity_min = calc_min
	motor_2.initial_velocity_max = calc_max
