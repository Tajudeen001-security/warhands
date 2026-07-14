extends Control
## Loadout.gd
## Weapon customization screen. Lets the player cycle through weapons
## and toggle attachments per slot (optic / grip / mag), then shows the
## resulting effective stats via GameState.get_effective_weapon_stats().

@onready var weapon_name_label: Label = $Margin/VBox/WeaponName
@onready var stats_label: Label = $Margin/VBox/StatsLabel
@onready var optic_label: Label = $Margin/VBox/OpticRow/OpticLabel
@onready var grip_label: Label = $Margin/VBox/GripRow/GripLabel
@onready var mag_label: Label = $Margin/VBox/MagRow/MagLabel

var weapon_ids: Array = ["pistol", "rifle", "sniper"]
var current_weapon_index: int = 1

var optic_options := ["", "scope_red_dot", "scope_4x"]
var grip_options := ["", "grip_angled", "grip_vertical"]
var mag_options := ["", "mag_extended", "mag_fast"]

func _ready() -> void:
	current_weapon_index = weapon_ids.find(GameState.equipped_weapon)
	if current_weapon_index == -1:
		current_weapon_index = 0
	_refresh()

func _current_weapon_id() -> String:
	return weapon_ids[current_weapon_index]

func _refresh() -> void:
	var wid := _current_weapon_id()
	var base: Dictionary = GameState.weapons[wid]
	var eff: Dictionary = GameState.get_effective_weapon_stats(wid)
	weapon_name_label.text = base["name"]
	stats_label.text = "DMG %d   MAG %d   RANGE %d   RELOAD %.1fs" % [
		eff["damage"], eff["mag_size"], int(eff["range"]), eff["reload_time"]
	]
	var mods: Dictionary = GameState.loadout.get(wid, {"optic": "", "grip": "", "mag": ""})
	optic_label.text = _display_name(mods.get("optic", ""))
	grip_label.text = _display_name(mods.get("grip", ""))
	mag_label.text = _display_name(mods.get("mag", ""))

func _display_name(att_id: String) -> String:
	if att_id == "":
		return "None"
	return att_id.replace("_", " ").capitalize()

func _cycle(options: Array, current: String, direction: int) -> String:
	var idx := options.find(current)
	if idx == -1:
		idx = 0
	idx = (idx + direction + options.size()) % options.size()
	return options[idx]

func _on_weapon_prev_pressed() -> void:
	current_weapon_index = (current_weapon_index - 1 + weapon_ids.size()) % weapon_ids.size()
	_refresh()

func _on_weapon_next_pressed() -> void:
	current_weapon_index = (current_weapon_index + 1) % weapon_ids.size()
	_refresh()

func _on_optic_next_pressed() -> void:
	var wid := _current_weapon_id()
	var mods: Dictionary = GameState.loadout[wid]
	mods["optic"] = _cycle(optic_options, mods.get("optic", ""), 1)
	_refresh()

func _on_grip_next_pressed() -> void:
	var wid := _current_weapon_id()
	var mods: Dictionary = GameState.loadout[wid]
	mods["grip"] = _cycle(grip_options, mods.get("grip", ""), 1)
	_refresh()

func _on_mag_next_pressed() -> void:
	var wid := _current_weapon_id()
	var mods: Dictionary = GameState.loadout[wid]
	mods["mag"] = _cycle(mag_options, mods.get("mag", ""), 1)
	_refresh()

func _on_equip_button_pressed() -> void:
	GameState.equipped_weapon = _current_weapon_id()
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
