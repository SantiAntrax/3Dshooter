extends EnemyState

func enter():
	enemy.linear_velocity = Vector3.ZERO

func physics_update(_delta: float):
	# No hace nada, la transición la manejan las señales del DetectionArea
	pass
