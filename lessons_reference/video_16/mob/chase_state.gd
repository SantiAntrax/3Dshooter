extends EnemyState

const ATTACK_RANGE: float = 2.5

func physics_update(_delta: float):
	var player = enemy.get_player()
	if not player:
		# Si no hay jugador, vuelve a idle (por seguridad)
		enemy.change_state("IdleState")
		return
	
	var dist = enemy.global_position.distance_to(player.global_position)
	
	# Si está al alcance de ataque, cambia a AttackState
	if dist <= ATTACK_RANGE:
		enemy.change_state("AttackState")
		return
	
	# Movimiento hacia el jugador
	var direction = enemy.global_position.direction_to(player.global_position)
	direction.y = 0.0
	enemy.linear_velocity = direction * enemy.speed
	
	# Rotación del modelo (ajusta según tu orientación)
	var target_angle = Vector3.FORWARD.signed_angle_to(direction, Vector3.UP) + PI
	enemy.bat_model.rotation.y = target_angle
