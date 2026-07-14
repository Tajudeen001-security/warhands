extends CharacterBody3D
## Bot.gd
## Simple bot "player" stand-in for real online opponents.
## State machine: PATROL -> CHASE (when player is within sight_range and
## has line of sight) -> ATTACK (within attack_range, fires on a timer).
## This is intentionally simple so it's cheap to run many bots on mobile;
## swap for NavigationAgent3D + pathfinding once real maps have nav meshes baked.

signal eliminated

enum State { PATROL, CHASE, ATTACK }

@export var move_speed: float = 3.2
@export var sight_range: float = 22.0
@export var attack_range: float = 16.0
@export var damage_per_hit: int = 8
@export var attack_interval: float = 1.4
@export var health: int = 90

@onready var patrol_points: Array = []
@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D

var state: int = State.PATROL
var patrol_index: int = 0
var attack_timer: float = 0.0
var target_player: Node3D = null
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready() -> void:
	add_to_group("bots")
	call_deferred("_find_patrol_points")

func _find_patrol_points() -> void:
	var parent_points := get_parent().get_node_or_null("BotPatrolPoints")
	if parent_points:
		for child in parent_points.get_children():
			patrol_points.append(child.global_transform.origin)
	if patrol_points.is_empty():
		patrol_points.append(global_transform.origin)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0

	target_player = _find_player_in_range()

	match state:
		State.PATROL:
			_do_patrol(delta)
			if target_player:
				state = State.CHASE
		State.CHASE:
			if not target_player:
				state = State.PATROL
			else:
				_do_chase(delta)
				if global_transform.origin.distance_to(target_player.global_transform.origin) <= attack_range:
					state = State.ATTACK
		State.ATTACK:
			if not target_player:
				state = State.PATROL
			elif global_transform.origin.distance_to(target_player.global_transform.origin) > attack_range * 1.2:
				state = State.CHASE
			else:
				_do_attack(delta)

	move_and_slide()

func _find_player_in_range() -> Node3D:
	var players := get_tree().get_nodes_in_group("players")
	for p in players:
		if not is_instance_valid(p):
			continue
		var dist: float = global_transform.origin.distance_to(p.global_transform.origin)
		if dist <= sight_range:
			var space_state := get_world_3d().direct_space_state
			var query := PhysicsRayQueryParameters3D.create(
				global_transform.origin + Vector3.UP * 1.2,
				p.global_transform.origin + Vector3.UP * 1.0
			)
			query.exclude = [self]
			var result := space_state.intersect_ray(query)
			if result.is_empty() or result.collider == p:
				return p
	return null

func _do_patrol(delta: float) -> void:
	if patrol_points.is_empty():
		return
	var target: Vector3 = patrol_points[patrol_index]
	var dir: Vector3 = (target - global_transform.origin)
	dir.y = 0
	if dir.length() < 1.0:
		patrol_index = (patrol_index + 1) % patrol_points.size()
		return
	dir = dir.normalized()
	velocity.x = dir.x * move_speed * 0.5
	velocity.z = dir.z * move_speed * 0.5
	look_at(global_transform.origin + Vector3(dir.x, 0, dir.z), Vector3.UP)

func _do_chase(delta: float) -> void:
	if not target_player:
		return
	var dir: Vector3 = (target_player.global_transform.origin - global_transform.origin)
	dir.y = 0
	dir = dir.normalized()
	velocity.x = dir.x * move_speed
	velocity.z = dir.z * move_speed
	look_at(global_transform.origin + Vector3(dir.x, 0, dir.z), Vector3.UP)

func _do_attack(delta: float) -> void:
	velocity.x = 0
	velocity.z = 0
	if target_player:
		var dir: Vector3 = (target_player.global_transform.origin - global_transform.origin)
		dir.y = 0
		if dir.length() > 0.01:
			look_at(global_transform.origin + dir, Vector3.UP)

	attack_timer -= delta
	if attack_timer <= 0.0:
		attack_timer = attack_interval
		if target_player and target_player.has_method("take_damage"):
			target_player.take_damage(damage_per_hit)

func take_damage(amount: int) -> void:
	health -= amount
	if health <= 0:
		eliminated.emit()
		queue_free()
