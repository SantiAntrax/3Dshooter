extends Panel

signal resume_game
signal restart_game
signal quit_to_menu

func _ready():
	# Conectar botones (asumiendo que los nombres son exactamente esos)
	$VBoxContainer/Reanudar.pressed.connect(_on_reanudar_pressed)
	$VBoxContainer/Reiniciar.pressed.connect(_on_reiniciar_pressed)
	$VBoxContainer/SalirMenu.pressed.connect(_on_salir_menu_pressed)

func _on_reanudar_pressed():
	emit_signal("resume_game")

func _on_reiniciar_pressed():
	emit_signal("restart_game")

func _on_salir_menu_pressed():
	emit_signal("quit_to_menu")
