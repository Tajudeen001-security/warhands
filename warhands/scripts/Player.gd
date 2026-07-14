extends CharacterBody3D
## Player.gd
## Third-person mobile shooter controller.
## - Left virtual joystick: movement
## - Right screen drag: camera look
## - Fire button: raycast shoot using the equipped weapon's stats
## - Weapon buttons: switch between unlocked weapons
##
## This is a single-player-against-bots prototype. To go online, this
## node's movement/shoot calls would be replaced with client-side
## prediction + server reconciliation via a networking backend
## (see README "Going Online" section).

signal died
signal health_changed(current: int, max: int)

@export var walk_speed: float = 5.5
@export var jump_velocity: float = 9.0
@export var look_sensitivity: float = 0.25

@onready var camera_pivot: Node3D = $CameraPivot
@onready var camera: Camera3D = $CameraPivot/SpringArm3D/Camera3D
@onready var muzzle: Marker3D = $CameraPivot/SpringArm3D/Camera3D/Muzzle
@onready var hud: CanvasLayer = $HUD

var max_health: int = 100
var current_health: int = 100
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

var move_input := Vector2.ZERO
var look_input := Vector2.ZERO

var current_ammo: int = 30
var is_reloading: bool = false

var _touch_move_index: int = -1
var _touch_look_index: int = -1
var _move_origin := Vector2.ZERO

func _ready() -> void:
	var char_data: Dictionary = GameState.get_selected_character()
	max_health = char_data["health"]
	current_health = max_health
	walk_speed *= char_data["speed_mult"]
	_reset_ammo_for_current_weapon()
	health_changed.emit(current_health, max_health)
	if hud and hud.has_method("bind_player"):
		hud.bind_player(self)

func _reset_ammo_for_current_weapon() -> void:
	var stats: Dictionary = GameState.get_effective_weapon_stats(GameState.equipped_weapon)
	current_ammo = stats["mag_size"]

# ---------------------------------------------------------------------------
# INPUT: touch joystick (left half of screen) + look drag (right half)
# ---------------------------------------------------------------------------
func _input(event: InputEvent) -> void:
	var screen_w: float = get_viewport().get_visible_rect().size.x

	if event is InputEventScreenTouch:
		if event.pressed:
			if event.position.x < screen_w * 0.5 and _touch_move_index == -1:
				_touch_move_index = event.index
				_move_origin = event.position
			elif event.position.x >= screen_w * 0.5 and _touch_look_index == -1:
				_touch_look_index = event.index
		else:
			if event.index == _touch_move_index:
				_touch_move_index = -1
				move_input = Vector2.ZERO
			elif event.index == _touch_look_index:
				_touch_look_index = -1

	elif event is InputEventScreenDrag:
		if event.index == _touch_move_index:
			var delta: Vector2 = event.position - _move_origin
			move_input = (delta / 60.0).limit_length(1.0)
		elif event.index == _touch_look_index:
			look_input = event.relative * look_sensitivity

func _unhandled_input(event: InputEvent) -> void:
	# Desktop testing fallback (WASD + mouse) so this can be tested
	# in the Godot editor before exporting to Android.
	if event is InputEventKey:
		var k := event as InputEventKey
		var v := Vector2.ZERO
		if Input.is_key_pressed(KEY_W): v.y -= 1
		if Input.is_key_pressed(KEY_S): v.y += 1
		if Input.is_key_pressed(KEY_A): v.x -= 1
		if Input.is_key_pressed(KEY_D): v.x += 1
		move_input = v.limit_length(1.0)
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		look_input = event.relative * look_sensitivity * 0.3

# ---------------------------------------------------------------------------
# PHYSICS / MOVEMENT
# ---------------------------------------------------------------------------
func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0

	# Rotate camera pivot from look input (yaw on body, pitch on camera arm)
	rotate_y(-deg_to_rad(look_input.x))
	camera_pivot.rotation.x = clamp(camera_pivot.rotation.x - deg_to_rad(look_input.y), -1.2, 1.2)
	look_input = Vector2.ZERO

	var forward: Vector3 = -transform.basis.z
	var right: Vector3 = transform.basis.x
	var move_dir: Vector3 = (forward * -move_input.y + right * move_input.x)
	if move_dir.length() > 0.01:
		move_dir = move_dir.normalized()
		velocity.x = move_dir.x * walk_speed
		velocity.z = move_dir.z * walk_speed
	else:
		velocity.x = move_toward(velocity.x, 0.0, walk_speed * 4.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, walk_speed * 4.0 * delta)

	move_and_slide()

# ---------------------------------------------------------------------------
# SHOOTING
# ---------------------------------------------------------------------------
func fire() -> void:
	if is_reloading or current_ammo <= 0:
		return
	var stats: Dictionary = GameState.get_effective_weapon_stats(GameState.equipped_weapon)
	current_ammo -= 1

	var spread: float = stats["spread"]
	var dir: Vector3 = -camera.global_transform.basis.z
	dir += Vector3(
		randf_range(-spread, spread),
		randf_range(-spread, spread),
		randf_range(-spread, spread)
	)
	dir = dir.normalized()

	var space_state := get_world_3d().direct_space_state
	var from: Vector3 = camera.global_transform.origin
	var to: Vector3 = from + dir * stats["range"]
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [self]
	var result := space_state.intersect_ray(query)

	if result and result.collider.has_method("take_damage"):
		result.collider.take_damage(stats["damage"])

	if hud and hud.has_method("update_ammo"):
		hud.update_ammo(current_ammo, stats["mag_size"])

	if current_ammo <= 0:
		reload()

func reload() -> void:
	if is_reloading:
		return
	is_reloading = true
	var stats: Dictionary = GameState.get_effective_weapon_stats(GameState.equipped_weapon)
	if hud and hud.has_method("show_reloading"):
		hud.show_reloading(stats["reload_time"])
	await get_tree().create_timer(stats["reload_time"]).timeout
	current_ammo = stats["mag_size"]
	is_reloading = false
	if hud and hud.has_method("update_ammo"):
		hud.update_ammo(current_ammo, stats["mag_size"])

func switch_weapon(weapon_id: String) -> void:
	if not GameState.weapons.has(weapon_id):
		return
	GameState.equipped_weapon = weapon_id
	_reset_ammo_for_current_weapon()
	var stats: Dictionary = GameState.get_effective_weapon_stats(weapon_id)
	if hud and hud.has_method("update_ammo"):
		hud.update_ammo(current_ammo, stats["mag_size"])
		hud.update_weapon_name(GameState.weapons[weapon_id]["name"])

# ---------------------------------------------------------------------------
# HEALTH
# ---------------------------------------------------------------------------
func take_damage(amount: int) -> void:
	current_health = max(0, current_health - amount)
	health_changed.emit(current_health, max_health)
	if hud and hud.has_method("update_health"):
		hud.update_health(current_health, max_health)
	if current_health <= 0:
		died.emit()
		_handle_death()

func _handle_death() -> void:
	set_physics_process(false)
	if hud and hud.has_method("show_eliminated"):
		hud.show_eliminated()
