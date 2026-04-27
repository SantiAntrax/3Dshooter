extends Node3D

@export var mob_scene: PackedScene
@export var spawn_points: Array[Node3D] = []
@export var spawn_radius: float = 2.0
@export var spawn_height_offset: float = 1.0
@export var enemies_share: int = 0   # 0 = reparto automático, >0 = límite fijo por ronda

var spawn_timer: Timer
var repopulate_delay: float = 0.5

var spawning_active: bool = false
var total_to_spawn: int = 0
var spawned_alive: int = 0
var pending_spawns: int = 0

signal mob_spawned(mob)

func _ready():
	if not mob_scene:
		push_error("ERROR: Asigna la escena del mob en el inspector del spawner.")
		return

	# Registrarse en el RoundManager para reparto automático
	RoundManager.register_spawner(self)

	spawn_timer = Timer.new()
	spawn_timer.one_shot = false
	spawn_timer.wait_time = repopulate_delay
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	add_child(spawn_timer)

	RoundManager.round_started.connect(_on_round_started)
	RoundManager.round_ended.connect(_on_round_ended)
	RoundManager.spawn_slot_available.connect(_on_slot_available)

func _exit_tree():
	RoundManager.unregister_spawner(self)

func _on_round_started(_round_number: int):
	spawning_active = true
	var total = RoundManager.enemies_to_spawn

	# Calcular cuota de este spawner
	if enemies_share > 0:
		pending_spawns = min(enemies_share, total)
	else:
		var count = RoundManager.get_spawner_count()
		if count > 0:
			pending_spawns = total / count
		else:
			pending_spawns = total

	total_to_spawn = pending_spawns
	spawned_alive = 0
	spawn_timer.start()

func _on_round_ended(_round_number: int):
	spawning_active = false
	pending_spawns = 0
	spawn_timer.stop()

func _on_spawn_timer_timeout():
	if not spawning_active or pending_spawns <= 0:
		spawn_timer.stop()
		return

	if RoundManager.try_reserve_spawn():
		_spawn_one()
		if pending_spawns <= 0:
			spawn_timer.stop()
	else:
		spawn_timer.stop()

func _on_slot_available():
	if spawning_active and pending_spawns > 0 and spawn_timer.is_stopped():
		if RoundManager.try_reserve_spawn():
			_spawn_one()
		else:
			spawn_timer.start()

func _spawn_one():
	if not mob_scene: return
	var mob = mob_scene.instantiate()
	if not mob: return

	add_child(mob)

	var base_pos: Vector3
	if spawn_points.size() > 0:
		var point = spawn_points[randi() % spawn_points.size()]
		base_pos = point.global_position
	else:
		base_pos = global_position

	var offset = Vector3(randf_range(-spawn_radius, spawn_radius), spawn_height_offset, randf_range(-spawn_radius, spawn_radius))
	mob.global_position = base_pos + offset

	mob.died.connect(_on_mob_died)

	spawned_alive += 1
	pending_spawns -= 1
	mob_spawned.emit(mob)

func _on_mob_died():
	spawned_alive -= 1
	RoundManager.release_spawn()
	if spawning_active and pending_spawns > 0 and spawn_timer.is_stopped():
		spawn_timer.start()
