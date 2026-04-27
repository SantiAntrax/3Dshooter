extends Node3D

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _on_jugar_pressed():
	get_tree().change_scene_to_file("res://lessons_reference/video_16/game.tscn")

func _on_salir_pressed():
	get_tree().quit()
