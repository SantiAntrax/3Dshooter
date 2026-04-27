extends Node3D

# UI de rondas
@onready var round_label = $CanvasLayer/RoundLabel
@onready var enemies_label = $CanvasLayer/EnemiesRemainingLabel
@onready var score_label = $CanvasLayer/ScoreLabel
@onready var message_panel = $CanvasLayer/RoundMessagePanel
@onready var message_label = $CanvasLayer/RoundMessagePanel/RoundMessageLabel
@onready var next_button = $CanvasLayer/RoundMessagePanel/NextRoundButton

# Paneles de final de partida
@onready var game_over_panel: Panel = $CanvasLayer/GameOverPanel
@onready var victory_panel: Panel = $CanvasLayer/VictoryPanel

# Panel de pausa
@onready var pause_panel: Panel = $CanvasLayer/PausePanel

var player_score = 0
var is_paused: bool = false
var game_ended: bool = false

func _ready():
	# Forzar ocultación de todos los paneles (seguridad)
	message_panel.visible = false
	game_over_panel.visible = false
	victory_panel.visible = false
	pause_panel.visible = false

	# Inicialización segura de textos
	if round_label: round_label.text = "Ronda 1"
	if enemies_label: enemies_label.text = "Enemigos: 0"
	if score_label: score_label.text = "Score: 0"

	# Reiniciar y arrancar rondas
	RoundManager.reset_rounds()
	RoundManager.setup_ui(round_label, enemies_label, message_panel, message_label, next_button)
	RoundManager.start_new_round()
	update_score()

	# Conectar señales de RoundManager para manejar pausa/ratón entre rondas
	RoundManager.round_message_show.connect(_on_round_message_show)
	RoundManager.round_message_hide.connect(_on_round_message_hide)

	# Conectar paneles de final de partida
	_connect_end_panels()

	# Conectar señal de muerte del jugador
	var player = get_node_or_null("Player")
	if player and player.has_signal("player_died"):
		player.player_died.connect(_on_player_died)

	# Conectar victoria desde RoundManager
	RoundManager.all_rounds_completed.connect(_on_victory)

	# Conectar señales del panel de pausa
	pause_panel.resume_game.connect(_on_pause_resume)
	pause_panel.restart_game.connect(_on_pause_restart)
	pause_panel.quit_to_menu.connect(_on_pause_quit)

func _connect_end_panels():
	game_over_panel.retry_pressed.connect(_retry)
	game_over_panel.menu_pressed.connect(_go_to_main_menu)
	victory_panel.retry_pressed.connect(_retry)
	victory_panel.menu_pressed.connect(_go_to_main_menu)

# --- Manejo de pausa/ratón para mensajes de ronda ---
func _on_round_message_show(_msg: String):
	get_tree().paused = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _on_round_message_hide():
	message_panel.visible = false   # ✅ Oculta el panel de "Siguiente Ronda"
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

# --- Lógica de pausa del jugador (ESC) ---
func _input(event):
	if event.is_action_pressed("ui_cancel"):
		if game_ended or RoundManager.is_between_rounds:
			return
		if is_paused:
			_unpause()
		else:
			_pause()

func _pause():
	get_tree().paused = true
	is_paused = true
	pause_panel.visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _unpause():
	get_tree().paused = false
	is_paused = false
	pause_panel.visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _on_pause_resume():
	_unpause()

func _on_pause_restart():
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_pause_quit():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://lessons_reference/video_16/main_menu.tscn")

# --- Fin de juego ---
func _on_player_died():
	if game_ended: return
	game_ended = true
	show_end_panel(game_over_panel)

func _on_victory():
	if game_ended: return
	game_ended = true
	show_end_panel(victory_panel)

func show_end_panel(panel: Panel):
	get_tree().paused = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	panel.set_score(player_score)
	panel.visible = true
	pause_panel.visible = false

func _retry():
	get_tree().paused = false
	get_tree().reload_current_scene()

func _go_to_main_menu():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://lessons_reference/video_16/main_menu.tscn")

# --- Puntuación y efectos (sin cambios) ---
func increase_score():
	player_score += 1
	update_score()

func update_score():
	if score_label: score_label.text = "Score: " + str(player_score)

func _on_mob_spawned(_mob):
	pass

func do_poof(mob_position):
	const SMOKE_PUFF = preload("res://mob/smoke_puff/smoke_puff.tscn")
	var poof = SMOKE_PUFF.instantiate()
	add_child(poof)
	poof.global_position = mob_position
