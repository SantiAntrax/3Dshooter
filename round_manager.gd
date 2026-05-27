extends Node

# Señales del ciclo de ronda
signal round_started(round_number: int)
signal round_ended(round_number: int)
signal all_rounds_completed()

# Señales para la UI
signal round_message_show(text: String)
signal round_message_hide

# Señal para avisar a los spawners de un hueco libre
signal spawn_slot_available

# ✅ Señal para actualizar la puntuación en la UI
signal score_updated(new_score: int)

var current_round: int = 1
var enemies_to_spawn: int = 0
var enemies_alive: int = 0
var is_between_rounds: bool = false

# ✅ Variable de puntuación acumulada
var current_score: int = 0

# Control global de enemigos simultáneos
var current_alive: int = 0

# Referencias a la UI
var round_label: Label
var enemies_label: Label
var message_panel: Panel
var message_label: Label
var next_button: Button

# Timer para avance automático
var auto_advance_timer: Timer
const AUTO_ADVANCE_TIME: float = 3.0

# Parámetros de dificultad
const BASE_ENEMIES = 9
const ENEMY_INCREMENT = 15
const MAX_ROUNDS = 5

# Límite de enemigos simultáneos
const BASE_MAX_ALIVE = 9
const MAX_ALIVE_INCREMENT = 2

# Registro de spawners para reparto automático
var spawners: Array = []

func _ready():
	auto_advance_timer = Timer.new()
	auto_advance_timer.one_shot = true
	auto_advance_timer.wait_time = AUTO_ADVANCE_TIME
	auto_advance_timer.timeout.connect(_on_auto_advance_timeout)
	add_child(auto_advance_timer)

func register_spawner(spawner):
	if not spawners.has(spawner):
		spawners.append(spawner)

func unregister_spawner(spawner):
	spawners.erase(spawner)

func get_spawner_count() -> int:
	return spawners.size()

func get_max_enemies_alive() -> int:
	var extra = (current_round - 1) / 3 * MAX_ALIVE_INCREMENT
	return BASE_MAX_ALIVE + extra

func try_reserve_spawn() -> bool:
	if current_alive < get_max_enemies_alive():
		current_alive += 1
		return true
	return false

func release_spawn():
	current_alive -= 1
	spawn_slot_available.emit()

func setup_ui(r_label: Label, e_label: Label, panel: Panel, m_label: Label, button: Button = null):
	round_label = r_label
	enemies_label = e_label
	message_panel = panel
	message_label = m_label
	next_button = button
	if next_button:
		next_button.pressed.connect(_on_next_round_pressed)
	update_ui()

func reset_rounds():
	current_round = 1
	enemies_alive = 0
	enemies_to_spawn = 0
	is_between_rounds = false
	current_alive = 0
	current_score = 0  # ✅ Reiniciar puntuación
	if auto_advance_timer:
		auto_advance_timer.stop()
	round_label = null
	enemies_label = null
	message_panel = null
	message_label = null
	next_button = null

func start_new_round():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	get_tree().paused = false

	if MAX_ROUNDS > 0 and current_round > MAX_ROUNDS:
		all_rounds_completed.emit()
		return

	enemies_to_spawn = BASE_ENEMIES + (current_round - 1) * ENEMY_INCREMENT
	enemies_alive = enemies_to_spawn
	is_between_rounds = false
	if is_instance_valid(message_panel):
		message_panel.visible = false

	round_message_hide.emit()
	round_started.emit(current_round)
	update_ui()

func on_enemy_spawned():
	pass

func on_enemy_died():
	enemies_alive -= 1
	# ✅ Sumar puntos y emitir señal
	current_score += 100
	score_updated.emit(current_score)
	# ✅ (Opcional) mensaje de depuración
	print("Enemigo muerto. Score actual: ", current_score)
	
	update_ui()
	if enemies_alive <= 0 and not is_between_rounds:
		_end_round()

func _end_round():
	round_ended.emit(current_round)
	is_between_rounds = true

	if MAX_ROUNDS > 0 and current_round >= MAX_ROUNDS:
		all_rounds_completed.emit()
		return

	current_round += 1
	_show_round_message()

func _show_round_message():
	var msg = "¡Ronda " + str(current_round) + "!"
	if is_instance_valid(message_label):
		message_label.text = msg
	if is_instance_valid(message_panel):
		message_panel.visible = true

	round_message_show.emit(msg)

	if auto_advance_timer:
		auto_advance_timer.start()

	if is_instance_valid(next_button):
		next_button.grab_focus()

func _on_next_round_pressed():
	if is_between_rounds:
		_advance_round()

func _on_auto_advance_timeout():
	if is_between_rounds:
		_advance_round()

func _advance_round():
	if auto_advance_timer:
		auto_advance_timer.stop()
	start_new_round()

func update_ui():
	if is_instance_valid(round_label):
		round_label.text = "Ronda " + str(current_round)
	if is_instance_valid(enemies_label):
		enemies_label.text = "Enemigos: " + str(enemies_alive)
