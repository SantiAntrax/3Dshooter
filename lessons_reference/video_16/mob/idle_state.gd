extends EnemyState

var idle_timer: float = 0.0
var wait_time: float = 0.5  # tiempo en idle antes de perseguir (puedes poner 0.0)

func enter() -> void:
	enemy.linear_velocity = Vector3.ZERO
	idle_timer = wait_time

func physics_update(delta: float) -> void:
	if idle_timer > 0:
		idle_timer -= delta
		if idle_timer <= 0:
			# Siempre cambiar a ChaseState, sin importar la distancia
			enemy.change_state("ChaseState")
