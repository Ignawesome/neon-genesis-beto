class_name Misil
extends Area2D

# ==============================================================================
# PROPIEDADES EXPORTADAS
# ==============================================================================

@export var velocidad_misil: float = 800.0  # El misil es rápido, idealmente más rápido que los enemigos.
@export var tiempo_maximo_de_vida: float = 0.5 # Se autodestruye después de 0.5 segundos.
@export var velocidad_de_giro := 9000.0
# Esta es la variable nueva que recibe del jugador
var velocidad_heredada: Vector2 = Vector2.ZERO 
# Variable para guardar el cálculo final
var velocidad_total: Vector2 = Vector2.ZERO

@export var fuerza_de_knockback: float = 800.0 

# ==============================================================================
# VARIABLES Y REFERENCIAS
# ==============================================================================

const ESCENA_MISIL = preload("uid://beqg12lmsofl8")

# Esta variable debe ser configurada por el Jugador.gd al momento de instanciar
# el misil. Permite que el daño del misil escale con el nivel del jugador.
var danio_a_infligir: float = 1.0 
var direccion: Vector2 = Vector2.RIGHT

@onready var tiempo_de_vida = $TiempoDeVida # Debe ser un nodo Timer hijo
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var sonido_explosion: AudioStreamPlayer2D = $SonidoExplosion


# ==============================================================================
# CONSTRUCTOR
# ==============================================================================

static func crear_misil(duracion: float, danio: float):
	var nuevo_misil: Misil = ESCENA_MISIL.instantiate()
	nuevo_misil.danio_a_infligir = danio
	nuevo_misil.tiempo_maximo_de_vida = duracion
	return nuevo_misil

# ==============================================================================
# FUNCIONES NATIVAS DE GODOT
# ==============================================================================

func _ready():
	# 1. Configurar y empezar el temporizador de autodestrucción
	tiempo_de_vida.wait_time = tiempo_maximo_de_vida
	tiempo_de_vida.one_shot = true # Solo se ejecuta una vez
	tiempo_de_vida.start()
	
	# 2. Conectar la señal de colisión (body_entered)
	# Esta señal detecta cuando un CharacterBody2D (el enemigo) entra en el Area2D.
	body_entered.connect(_on_body_entered)

func _process(delta):
	# Mover el misil constantemente en la dirección asignada
	global_position += direccion * velocidad_misil * delta

# ==============================================================================
# MANEJADORES DE SEÑALES
# ==============================================================================

# Se llama cuando el temporizador de tiempo de vida se agota
func _on_tiempo_de_vida_timeout():
	# Si no golpeó a nadie a tiempo, se elimina solo
	queue_free()

# Se llama cuando el misil golpea un cuerpo físico
func _on_body_entered(body: Node2D):
	# Usamos 'is' para verificar si el cuerpo golpeado es una instancia de la clase Enemigo
	if body is Enemigo or body is Jugador:
		# 1. Aplicar daño al enemigo
		body.recibir_danio(danio_a_infligir)
		
		# 2. APLICAR KNOCKBACK
		# Verificamos si el cuerpo tiene la función creada antes de llamarla
		if body.has_method("aplicar_knockback"):
			# El empuje va en la misma dirección que el misil
			var vector_empuje = direccion * fuerza_de_knockback
			body.aplicar_knockback(vector_empuje)
		
		# 3. Reproducir animacion de explosion
		explotar()
	
	# Importante: Si golpea otros cuerpos (como rocas o corales, que son StaticBody2D)
	# el misil simplemente debe atravesarlos, o bien podrías agregar aquí un "queue_free()"
	# si quisieras que el misil se destruya contra rocas. Por ahora, solo se destruye
	# al golpear un enemigo.
	
func explotar() -> void:
	sonido_explosion.pitch_scale = sonido_explosion.pitch_scale + randf_range(-0.2, 0.2)
	animation_player.play("explotar")
