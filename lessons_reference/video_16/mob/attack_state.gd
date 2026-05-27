extends EnemyState

func enter() -> void:
	# Detenerse para atacar
	enemy.linear_velocity = Vector3.ZERO

func physics_update(_delta: float) -> void:
	var player = enemy.get_player()
	if not player:
		enemy.change_state("IdleState")
		return
	
	# Si no hay jugadores en el área de daño, volver a perseguir
	if enemy.players_in_range.is_empty():
		enemy.change_state("ChaseState")
		return
	
	# Rotar hacia el jugador continuamente
	_face_player()
	
	# Intentar atacar si el cooldown lo permite
	if enemy.can_attack and enemy.attack_cooldown_timer.is_stopped():
		enemy.try_attack()

func _face_player() -> void:
	var player = enemy.get_player()
	if not player:
		return
	var dir = player.global_position - enemy.global_position
	dir.y = 0.0
	if dir.length() > 0.001:
		enemy.bat_model.rotation.y = Vector3.FORWARD.signed_angle_to(dir.normalized(), Vector3.UP) + PI
