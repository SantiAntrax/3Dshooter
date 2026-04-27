extends CharacterBody3D

signal player_died

var vida = 100
var is_dead = false

@onready var health_ui = $"CanvasLayer/player_health_bar"   # Ajusta la ruta a tu ProgressBar
@onready var camera = %Camera3D

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	add_to_group("player")
	is_dead = false
	if health_ui:
		health_ui.value = vida

func _unhandled_input(event):
	if is_dead:
		return
	if event is InputEventMouseMotion:
		rotation_degrees.y -= event.relative.x * 0.5
		camera.rotation_degrees.x -= event.relative.y * 0.2
		camera.rotation_degrees.x = clamp(camera.rotation_degrees.x, -60.0, 60.0)

func _physics_process(delta):
	if is_dead:
		return
	const SPEED = 5.5
	var input_direction_2D = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var input_direction_3D = Vector3(input_direction_2D.x, 0, input_direction_2D.y)
	var direction = transform.basis * input_direction_3D
	velocity.x = direction.x * SPEED
	velocity.z = direction.z * SPEED
	velocity.y -= 20.0 * delta

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = 10.0
	elif Input.is_action_just_released("jump") and velocity.y > 0.0:
		velocity.y = 0.0

	move_and_slide()

	if Input.is_action_pressed("shoot") and %Timer.is_stopped():
		shoot_bullet()

func shoot_bullet():
	const BULLET = preload("bullet_3d.tscn")
	var new_bullet = BULLET.instantiate()
	%Marker3D.add_child(new_bullet)
	new_bullet.global_transform = %Marker3D.global_transform
	%Timer.start()
	%AudioStreamPlayer.play()

func recibir_daño(cantidad):
	if is_dead:
		return
	vida -= cantidad
	vida = clamp(vida, 0, 100)
	if health_ui:
		health_ui.value = vida
	if vida <= 0:
		morir()

func morir():
	if is_dead:
		return
	is_dead = true
	print("Has muerto")
	set_process(false)
	set_physics_process(false)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	player_died.emit()
