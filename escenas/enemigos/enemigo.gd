class_name Enemigo
extends CharacterBody2D

# ==============================================================================
# PROPIEDADES BASE DEL ENEMIGO (Configurable por cada criatura)
# ==============================================================================

@export var velocidad_de_movimiento: float = 100.0  # Velocidad de persecución hacia el jugador
@export var puntos_de_salud_maximos: float = 3.0    # Vida inicial del enemigo
@export var danio_por_contacto: float = 1.0         # Daño que hace al tocar al jugador
@export var recompensa_xp: float = 1.0              # Cantidad de XP que suelta al morir
@export var probabilidad_orbe_hp: float = 0.333     # Chance de que suelte un orbe de HP
@export var material_daño: ShaderMaterial = preload("uid://derpqkc1oebjk")

@export var duración_de_misil := 10
@export var fuerza_de_ataque := 1
@export var velocidad_de_giro: float = 5.0 

# ==============================================================================
# VARIABLES Y REFERENCIAS
# ==============================================================================

var salud_actual: float
var objetivo: Node2D = null # Referencia al Jugador
var esta_muerto: bool = false

# Asegúrate de que tu escena Enemigo.tscn tenga un Area2D llamado "Hitbox"

@onready var hitbox: Area2D = %Hitbox
@onready var hurtbox: Area2D = %Hurtbox
@onready var sonido_disparo: AudioStreamPlayer2D = $SonidoDisparo

# ==============================================================================
# FUNCIONES NATIVAS DE GODOT
# ==============================================================================

func _ready() -> void:
	salud_actual = puntos_de_salud_maximos
	
	# Conectar la señal para detectar cuando el enemigo toca al jugador
	if hitbox:
		hitbox.body_entered.connect(_on_hitbox_body_entered)


func _physics_process(delta) -> void:
	if esta_muerto or not objetivo:
		return

	# 1. Dirección hacia el jugador (vector normalizado)
	var direccion = global_position.direction_to(objetivo.global_position)
	
	# 2. Aplicar el movimiento (podés multiplicar directamente el vector, es más limpio)
	velocity = direccion * velocidad_de_movimiento
	move_and_slide()
	
	# 3. Calcular hacia dónde tiene que mirar
	# .angle() convierte el vector de dirección en radianes
	var angulo_objetivo = direccion.angle()
	
	# COMPENSACIÓN: Como tu sprite mira hacia arriba, sumamos 90 grados (PI/2)
	angulo_objetivo += PI / 2.0
	
	# 4. Aplicar la rotación suavemente
	rotation = lerp_angle(rotation, angulo_objetivo, velocidad_de_giro * delta)

# ==============================================================================
# COMBATE Y DAÑO
# ==============================================================================

# Se llama desde el Misil.gd cuando golpea a este enemigo
func recibir_danio(cantidad_de_danio: float):
	if esta_muerto:
		return
		
	salud_actual -= cantidad_de_danio
	
	material = material_daño
	await get_tree().create_timer(0.25).timeout
	material = null
	
	# print("Enemigo golpeado, HP restante: %f" % salud_actual) # Mostrar en consola
	
	if salud_actual <= 0:
		morir.call_deferred()


# Se activa cuando el Hitbox del enemigo toca un CharacterBody2D
func _on_hitbox_body_entered(body: Node2D):
	# Verificamos si lo que golpeamos es el jugador (usando el class_name)
	if body is Jugador:
		var jugador_detectado: Jugador = body
		# Llamar a la función del jugador para hacerle daño y activar la lógica de esquiva
		jugador_detectado.recibir_danio(danio_por_contacto)
		
		# Eliminamos al enemigo por contacto (como en Vampire Survivors)
		# En una versión más avanzada, se podría usar un cooldown
		morir.call_deferred()


# ==============================================================================
# PROYECTILES
# ==============================================================================

func lanzar_misil_a_direccion(direccion_de_disparo: Vector2) -> void:
	var nuevo_misil: Misil = Misil.crear_misil(duración_de_misil, fuerza_de_ataque)
	
	# 1. Posicionamiento: Lanzamos el misil desde el centro del jugador
	get_parent().add_child(nuevo_misil) # Lo añadimos al nodo principal (Mundo)
	nuevo_misil.global_position = global_position
	nuevo_misil.set_collision_layer_value(5, true) 
	nuevo_misil.set_collision_layer_value(7, false)
	nuevo_misil.set_collision_mask_value(2, false)
	nuevo_misil.set_collision_mask_value(6, false)
	nuevo_misil.set_collision_mask_value(1, true)
	# 2. Configuración: Le pasamos la dirección y el daño
	nuevo_misil.direccion = direccion_de_disparo.normalized()
	nuevo_misil.danio_a_infligir = fuerza_de_ataque
	sonido_disparo.play()


# ==============================================================================
# MUERTE Y RECOMPENSAS
# ==============================================================================

func morir():
	if esta_muerto:
		return
		
	esta_muerto = true

	# Genera un numero aleatorio entre 0 y 1 y chequea contra la probabilidad de orbe HP
	var recupera_hp: bool
	
	if probabilidad_orbe_hp > randf():
		recupera_hp = true
	else:
		recupera_hp = false
	
	if recupera_hp:
		spawnear_orbe_hp()

	spawnear_orbe_xp()

	# 2. Eliminar el nodo de la escena
	queue_free()


func spawnear_orbe_xp():
	var nueva_orbe: OrbeDrop = OrbeDrop.crear_orbe_xp(recompensa_xp)
	Globales.contenedor_objetos.add_child(nueva_orbe)
	nueva_orbe.global_position = global_position + Vector2(randf_range(-50, 50), randf_range(-50, 50))


func spawnear_orbe_hp():
	var nueva_orbe: OrbeDrop = OrbeDrop.crear_orbe_hp()
	Globales.contenedor_objetos.add_child(nueva_orbe)
	nueva_orbe.global_position = global_position + Vector2(randf_range(-50, 50), randf_range(-50, 50))


func _on_deteccion_body_entered(body: Node2D) -> void:
	if body is Jugador:
		objetivo = body


#func _on_deteccion_body_exited(body: Node2D) -> void:
	#if body is Jugador:
		#objetivo = null


func _on_timer_misil_timeout() -> void:
	if objetivo:
		var direccion_de_disparo := global_position.direction_to(objetivo.global_position)
		lanzar_misil_a_direccion(direccion_de_disparo)
