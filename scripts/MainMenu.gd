extends Control
## MainMenu.gd
## Character carousel + map picker + play button.
## Reads/writes selections into the GameState autoload.

@onready var char_name_label: Label = $Margin/VBox/CharPanel/CharName
@onready var char_stats_label: Label = $Margin/VBox/CharPanel/CharStats
@onready var map_name_label: Label = $Margin/VBox/MapPanel/MapName
@onready var play_button: Button = $Margin/VBox/PlayButton

func _ready() -> void:
	_refresh_character()
	_refresh_map()

func _refresh_character() -> void:
	var c: Dictionary = GameState.characters[GameState.selected_character_index]
	char_name_label.text = c["name"]
	char_stats_label.text = "HP %d   SPD x%.2f" % [c["health"], c["speed_mult"]]

func _refresh_map() -> void:
	var m: Dictionary = GameState.maps[GameState.selected_map_index]
	map_name_label.text = m["name"]

func _on_char_prev_pressed() -> void:
	var n := GameState.characters.size()
	GameState.selected_character_index = (GameState.selected_character_index - 1 + n) % n
	_refresh_character()

func _on_char_next_pressed() -> void:
	var n := GameState.characters.size()
	GameState.selected_character_index = (GameState.selected_character_index + 1) % n
	_refresh_character()

func _on_map_prev_pressed() -> void:
	var n := GameState.maps.size()
	GameState.selected_map_index = (GameState.selected_map_index - 1 + n) % n
	_refresh_map()

func _on_map_next_pressed() -> void:
	var n := GameState.maps.size()
	GameState.selected_map_index = (GameState.selected_map_index + 1) % n
	_refresh_map()

func _on_play_button_pressed() -> void:
	var target: String = GameState.maps[GameState.selected_map_index]["scene"]
	get_tree().change_scene_to_file(target)

func _on_loadout_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Loadout.tscn")
