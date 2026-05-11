extends CharacterBody3D

signal player_died

# Salud
var vida = 100
var is_dead = false

# Controles táctiles
var touch_move_vector: Vector2 = Vector2.ZERO
var touch_shoot_pressed: bool = false
var touch_ui = null

# Sensibilidad de cámara
var camera_sensitivity_mobile: float = 0.096
var camera_sensitivity_pc: float = 0.0040

# Referencias a nodos existentes
@onready var health_ui = $"CanvasLayer/player_health_bar"
@onready var camera = %Camera3D
@onready var timer = %Timer
@onready var audio_player = %AudioStreamPlayer
@onready var marker = %Marker3D

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	add_to_group("player")
	is_dead = false
	if health_ui:
		health_ui.value = vida
	
	if OS.has_feature("mobile"):
		_setup_touch_ui()

func _setup_touch_ui():
	touch_ui = preload("res://TouchUI.tscn").instantiate()
	add_child(touch_ui)
	
	# Conectar joystick (nodo "VirtualJoystick")
	var joystick = touch_ui.get_node("VirtualJoystick")
	if joystick and joystick.has_signal("analogic_changed"):
		joystick.connect("analogic_changed", Callable(self, "_on_joystick_moved"))
		print("Joystick conectado")
	else:
		print("Error: No se encontró el nodo 'VirtualJoystick' o no tiene señal 'analogic_changed'")
	
	# Conectar botón de disparo (nodo "ShootButton")
	var shoot_btn = touch_ui.get_node("ShootButton")
	if shoot_btn and shoot_btn is TouchScreenButton:
		shoot_btn.connect("pressed", Callable(self, "_on_shoot_pressed"))
		shoot_btn.connect("released", Callable(self, "_on_shoot_released"))
		print("Botón de disparo conectado")
	else:
		print("Error: No se encontró el nodo 'ShootButton' o no es un TouchScreenButton")

# Señal del joystick (analogic_changed)
func _on_joystick_moved(value: Vector2, _distance: float, _angle: float, _angle_cw: float, _angle_ccw: float):
	touch_move_vector = value

func _on_shoot_pressed():
	touch_shoot_pressed = true

func _on_shoot_released():
	touch_shoot_pressed = false

func _unhandled_input(event):
	if is_dead:
		return
	
	var sens = camera_sensitivity_pc if not OS.has_feature("mobile") else camera_sensitivity_mobile
	
	if OS.has_feature("mobile"):
		if event is InputEventScreenDrag:
			_rotate_camera(event.relative.x, event.relative.y, sens)
	else:
		if event is InputEventMouseMotion:
			_rotate_camera(event.relative.x, event.relative.y, sens)

func _rotate_camera(delta_x: float, delta_y: float, sensitivity: float):
	rotation_degrees.y -= delta_x * sensitivity
	camera.rotation_degrees.x -= delta_y * sensitivity
	camera.rotation_degrees.x = clamp(camera.rotation_degrees.x, -60.0, 60.0)

func _physics_process(delta):
	if is_dead:
		return
	
	const SPEED = 5.5
	
	# Movimiento: joystick en móvil, teclado en PC
	var input_dir: Vector2
	if OS.has_feature("mobile"):
		input_dir = touch_move_vector
	else:
		input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	
	var move_3d = Vector3(input_dir.x, 0, input_dir.y).normalized()
	var direction = transform.basis * move_3d
	velocity.x = direction.x * SPEED
	velocity.z = direction.z * SPEED
	velocity.y -= 20.0 * delta
	
	# Salto
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = 10.0
	elif Input.is_action_just_released("jump") and velocity.y > 0.0:
		velocity.y = 0.0
	
	move_and_slide()
	
	# Disparo: botón táctil en móvil, ratón/teclado en PC
	if OS.has_feature("mobile"):
		if touch_shoot_pressed and timer.is_stopped():
			shoot_bullet()
	else:
		if Input.is_action_pressed("shoot") and timer.is_stopped():
			shoot_bullet()

func shoot_bullet():
	const BULLET = preload("bullet_3d.tscn")
	var new_bullet = BULLET.instantiate()
	marker.add_child(new_bullet)
	new_bullet.global_transform = marker.global_transform
	timer.start()
	audio_player.play()

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
