extends VBoxContainer


@onready var tutorial_esquivar: HBoxContainer = %TutorialEsquivar
@onready var tutorial_disparar: HBoxContainer = %TutorialDisparar
@onready var tutorial_anillo: HBoxContainer = %TutorialAnillo
@onready var tutorial_acelerar: HBoxContainer = %TutorialAcelerar
@onready var tutorial_girar: HBoxContainer = %TutorialGirar

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("arriba"):
		tutorial_acelerar.hide()
	if event.is_action_pressed("izquierda") or event.is_action_pressed("derecha"):
		tutorial_girar.hide()
	if event.is_action_pressed("disparar"):
		tutorial_disparar.hide()
	if event.is_action_pressed("ulti"):
		tutorial_anillo.hide()
	if event.is_action_pressed("esquivar"):
		tutorial_esquivar.hide()
