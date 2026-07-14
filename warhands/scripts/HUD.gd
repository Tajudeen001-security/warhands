extends CanvasLayer
## HUD.gd
## Mobile on-screen UI: health bar, ammo counter, fire button, weapon
## switch buttons, reload indicator, and elimination/victory banners.

@onready var health_bar: ProgressBar = $HealthBar
@onready var health_label: Label = $HealthLabel
@onready var ammo_label: Label = $AmmoLabel
@onready var weapon_label: Label = $WeaponLabel
@onready var fire_button: TouchScreenButton = $FireButton
@onready var reload_label: Label = $ReloadLabel
@onready var banner_label: Label = $BannerLabel

var _player: Node = null

func bind_player(player: Node) -> void:
	_player = player
	var stats: Dictionary = GameState.get_effective_weapon_stats(GameState.equipped_weapon)
	update_ammo(stats["mag_size"], stats["mag_size"])
	update_weapon_name(GameState.weapons[GameState.equipped_weapon]["name"])
	update_health(player.current_health, player.max_health)
	reload_label.visible = false
	banner_label.visible = false

func update_health(current: int, max_hp: int) -> void:
	health_bar.max_value = max_hp
	health_bar.value = current
	health_label.text = "%d / %d" % [current, max_hp]

func update_ammo(current: int, mag_size: int) -> void:
	ammo_label.text = "%d / %d" % [current, mag_size]

func update_weapon_name(name_str: String) -> void:
	weapon_label.text = name_str

func show_reloading(duration: float) -> void:
	reload_label.visible = true
	reload_label.text = "Reloading..."
	await get_tree().create_timer(duration).timeout
	reload_label.visible = false

func show_eliminated() -> void:
	banner_label.visible = true
	banner_label.text = "ELIMINATED"

func show_victory() -> void:
	banner_label.visible = true
	banner_label.text = "VICTORY ROYALE"

func _on_fire_button_pressed() -> void:
	if _player and _player.has_method("fire"):
		_player.fire()

func _on_reload_button_pressed() -> void:
	if _player and _player.has_method("reload"):
		_player.reload()

func _on_weapon_1_pressed() -> void:
	if _player: _player.switch_weapon("pistol")

func _on_weapon_2_pressed() -> void:
	if _player: _player.switch_weapon("rifle")

func _on_weapon_3_pressed() -> void:
	if _player: _player.switch_weapon("sniper")

func _on_exit_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
