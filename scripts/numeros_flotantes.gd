class_name NumeroFlotante
extends Label

static func crear_numero(numero: int, posicion_inicial: Vector2) -> NumeroFlotante:
	var label := NumeroFlotante.new()
	label.text = str(numero)
	
	# Centramos el texto para que la posición sea exacta
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.global_position = posicion_inicial
	label.scale = Vector2(3.5,3.5)
	label.add_theme_constant_override("outline_size", 2)
	
	# Opcional: Podés cargar un tema o color si querés
	label.modulate = Color.RED 
	
	return label

func _ready() -> void:
	# 1. Definimos una distancia en píxeles mucho mayor
	var movimiento_random = Vector2(randf_range(-50.0, 50.0), randf_range(-50.0, -100.0))
	
	# 2. Creamos el Tween y lo ponemos en paralelo (para que anime posición y color a la vez)
	var tween = create_tween().set_parallel(true)
	
	var tiempo_animacion = 0.6 # Segundos que dura el número en pantalla
	
	# Animar posición: desde donde está hacia la nueva posición
	# Usamos TRANS_CUBIC y EASE_OUT para que salga rápido y frene suavemente
	tween.tween_property(self, "global_position", global_position + movimiento_random, tiempo_animacion).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	# Animar transparencia: bajamos el Alpha (modulate:a) de 1.0 a 0.0
	tween.tween_property(self, "modulate:a", 0.0, tiempo_animacion)
	
	# 3. Al terminar todo lo anterior, lo destruimos para liberar memoria
	tween.chain().tween_callback(queue_free)
