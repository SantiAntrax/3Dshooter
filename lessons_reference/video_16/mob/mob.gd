extends RigidBody3D
class_name Mob

signal died
signal damaged(amount: int)

enum State { IDLE, CHASE, ATTACK }
var current_state: State = State.IDLE

var health: int = 3
var speed: float = 0.0
var player_in_damage_range: bool = false
var player_in_sight_range: bool = false
var is_dead: bool = false
var player: CharacterBody3D = null

@onready var bat_model: Node3D = %bat_model
@onready var damage_area: Area3D = $DamageArea
@onready var detection_area: Area3D = $DetectionArea
@onready var attack_timer: Timer = $AttackTimer
@onready var reaction_timer: Timer = $ReactionTimer
@onready var hurt_sound: AudioStreamPlayer3D = %HurtSound
@onready var ko_sound: AudioStreamPlayer3D = %KOSound
@onready var attack_sound: AudioStreamPlayer3D = %AttackSound
@onready var death_timer: Timer = %Timer

var original_material: Material = null

const ATTACK_DAMAGE: int = 10
const ATTACK_COOLDOWN: float = 1.0
const SIGHT_RANGE: float = 12.0
const ATTACK_RANGE: float = 2.5
const REACTION_DELAY: float = 0.3

func _ready():
	speed = randf_range(2.0, 4.0)

	damage_area.body_entered.connect(_on_damage_area_body_entered)
	damage_area.body_exited.connect(_on_damage_area_body_exited)
	detection_area.body_entered.connect(_on_detection_area_body_entered)
	detection_area.body_exited.connect(_on_detection_area_body_exited)

	attack_timer.one_shot = true
	attack_timer.timeout.connect(_on_attack_timer_timeout)
	reaction_timer.one_shot = true
	reaction_timer.timeout.connect(_on_reaction_timer_timeout)
	death_timer.timeout.connect(_on_timer_timeout)      # Conexión añadida por si no está en el editor

	_update_player_reference()
	current_state = State.IDLE

func _update_player_reference():
	player = get_tree().get_first_node_in_group("player")

func _physics_process(_delta: float):
	if not is_instance_valid(player):
		_update_player_reference()
		if not player:
			return

	match current_state:
		State.IDLE:
			linear_velocity = Vector3.ZERO

		State.CHASE:
			var direction = global_position.direction_to(player.global_position)
			direction.y = 0.0
			linear_velocity = direction * speed
			bat_model.rotation.y = Vector3.FORWARD.signed_angle_to(direction, Vector3.UP) + PI

			var dist = global_position.distance_to(player.global_position)
			if dist <= ATTACK_RANGE:
				current_state = State.ATTACK

		State.ATTACK:
			linear_velocity = Vector3.ZERO
			var dir = player.global_position - global_position
			dir.y = 0.0
			if dir.length() > 0.001:
				bat_model.rotation.y = Vector3.FORWARD.signed_angle_to(dir.normalized(), Vector3.UP) + PI

			if not player_in_damage_range:
				current_state = State.CHASE
				return

			if attack_timer.is_stopped():
				_attack_player(player)

func _attack_player(target: CharacterBody3D):
	if attack_sound:
		attack_sound.pitch_scale = randf_range(0.9, 1.1)
		attack_sound.play()

	if is_instance_valid(target) and target.has_method("recibir_daño"):
		target.recibir_daño(ATTACK_DAMAGE)

	attack_timer.start(ATTACK_COOLDOWN)

func _on_attack_timer_timeout():
	pass

func _on_reaction_timer_timeout():
	if player_in_sight_range and current_state == State.IDLE:
		current_state = State.CHASE

func _on_damage_area_body_entered(body: Node3D):
	if body.is_in_group("player"):
		player_in_damage_range = true

func _on_damage_area_body_exited(body: Node3D):
	if body.is_in_group("player"):
		player_in_damage_range = false

func _on_detection_area_body_entered(body: Node3D):
	if body.is_in_group("player"):
		player_in_sight_range = true
		if current_state == State.IDLE:
			reaction_timer.start(REACTION_DELAY)

func _on_detection_area_body_exited(body: Node3D):
	if body.is_in_group("player"):
		player_in_sight_range = false
		reaction_timer.stop()
		if current_state == State.CHASE:
			current_state = State.IDLE

func take_damage():
	if is_dead or health <= 0:
		return

	health -= 1
	damaged.emit(1)

	hurt_sound.pitch_scale = randfn(1.0, 0.1)
	hurt_sound.play()

	_flash_hurt()

	if bat_model.has_method("hurt"):
		bat_model.hurt()

	if health <= 0:
		die()

func _flash_hurt():
	if not bat_model is MeshInstance3D:
		return
	var mesh: MeshInstance3D = bat_model
	if not original_material:
		original_material = mesh.get_surface_override_material(0)

	var flash_material: Material
	if original_material:
		flash_material = original_material.duplicate()
	else:
		flash_material = StandardMaterial3D.new()
	flash_material.albedo_color = Color.RED
	mesh.set_surface_override_material(0, flash_material)

	await get_tree().create_timer(0.1).timeout
	if is_instance_valid(mesh):
		mesh.set_surface_override_material(0, original_material)

func die():
	if is_dead:
		return
	is_dead = true

	ko_sound.play()

	set_physics_process(false)
	damage_area.monitoring = false
	detection_area.monitoring = false
	attack_timer.stop()
	reaction_timer.stop()

	if RoundManager:
		RoundManager.on_enemy_died()

	gravity_scale = 1.0
	if player:
		var direction = player.global_position.direction_to(global_position)
		var impulse = direction * 10.0 + Vector3.UP * randf_range(2.0, 7.0)
		apply_central_impulse(impulse)
		var torque = Vector3(randf_range(-5.0, 5.0), randf_range(-2.0, 2.0), randf_range(-5.0, 5.0))
		apply_torque_impulse(torque)

	died.emit()
	death_timer.start()

func _on_timer_timeout():
	queue_free()
