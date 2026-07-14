extends Control
## Boot.gd
## Plays the studio/publisher splash sequence, then a loading bar,
## then transitions to the main menu. Mirrors the flow of COD Mobile /
## PUBG Mobile boots: publisher logo -> license/engine logo -> game logo
## -> progress bar -> menu.

@onready var logo_label: Label = $CenterContainer/LogoLabel
@onready var sub_label: Label = $CenterContainer/SubLabel
@onready var progress_bar: ProgressBar = $LoadingBar
@onready var progress_label: Label = $LoadingLabel

# Each stage: text shown, subtext shown, how long it stays on screen (seconds)
var stages := [
	{"text": "JagX", "sub": "", "hold": 1.2},
	{"text": "JRILICENSE", "sub": "ENGINE TECHNOLOGY", "hold": 1.2},
	{"text": "warHands", "sub": "", "hold": 1.5},
]

var current_stage: int = 0

func _ready() -> void:
	progress_bar.visible = false
	progress_label.visible = false
	_play_stage(0)

func _play_stage(index: int) -> void:
	if index >= stages.size():
		_start_loading_bar()
		return

	var stage: Dictionary = stages[index]
	logo_label.text = stage["text"]
	sub_label.text = stage["sub"]
	logo_label.modulate.a = 0.0
	sub_label.modulate.a = 0.0

	var tween := create_tween()
	tween.tween_property(logo_label, "modulate:a", 1.0, 0.35)
	tween.parallel().tween_property(sub_label, "modulate:a", 1.0, 0.35)
	tween.tween_interval(stage["hold"])
	tween.tween_property(logo_label, "modulate:a", 0.0, 0.25)
	tween.parallel().tween_property(sub_label, "modulate:a", 0.0, 0.25)
	tween.tween_callback(func():
		current_stage += 1
		_play_stage(current_stage)
	)

func _start_loading_bar() -> void:
	logo_label.text = "warHands"
	logo_label.modulate.a = 1.0
	sub_label.visible = false
	progress_bar.visible = true
	progress_label.visible = true

	var tween := create_tween()
	# Simulated asset load. Replace with real load_threaded_* progress
	# once actual map/character assets are streamed.
	tween.tween_method(_on_progress_update, 0.0, 100.0, 1.8)
	tween.tween_interval(0.3)
	tween.tween_callback(_go_to_menu)

func _on_progress_update(value: float) -> void:
	progress_bar.value = value
	progress_label.text = "Loading... %d%%" % int(value)

func _go_to_menu() -> void:
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
