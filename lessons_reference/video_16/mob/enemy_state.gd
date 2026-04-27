extends Node
class_name EnemyState

# Usamos Node en lugar de Mob para evitar dependencia de tipo
var enemy: Node

func enter() -> void:
	pass

func exit() -> void:
	pass

func physics_update(_delta: float) -> void:
	pass
