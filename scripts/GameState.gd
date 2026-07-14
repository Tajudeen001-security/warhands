extends Node
## GameState.gd
## Global autoload singleton. Holds data that must survive scene changes:
## which character/map was picked, current loadout, and weapon definitions.
## This is a stand-in for what a real backend/matchmaking service would
## track per-player in an online build.

# ---------------------------------------------------------------------------
# CHARACTERS
# ---------------------------------------------------------------------------
var characters := [
	{"id": "raider",  "name": "Raider",  "speed_mult": 1.05, "health": 100, "color": Color(0.75, 0.25, 0.2)},
	{"id": "ghost",   "name": "Ghost",   "speed_mult": 1.15, "health": 85,  "color": Color(0.6, 0.6, 0.65)},
	{"id": "juggernaut", "name": "Juggernaut", "speed_mult": 0.9, "health": 130, "color": Color(0.2, 0.3, 0.6)},
	{"id": "viper",   "name": "Viper",   "speed_mult": 1.0, "health": 100, "color": Color(0.2, 0.55, 0.25)},
]
var selected_character_index: int = 0

# ---------------------------------------------------------------------------
# WEAPONS  (base stats; customization mods apply multipliers on top)
# ---------------------------------------------------------------------------
var weapons := {
	"pistol": {
		"name": "M9 Sidearm", "damage": 18, "fire_rate": 0.35, "mag_size": 12,
		"reload_time": 1.2, "range": 40.0, "spread": 0.02
	},
	"rifle": {
		"name": "AR-Vanta", "damage": 24, "fire_rate": 0.12, "mag_size": 30,
		"reload_time": 2.0, "range": 80.0, "spread": 0.045
	},
	"sniper": {
		"name": "R-Longshot", "damage": 85, "fire_rate": 1.1, "mag_size": 5,
		"reload_time": 2.6, "range": 200.0, "spread": 0.005
	},
}

# Attachment mods: each modifies a stat by an additive/multiplicative amount.
var attachments := {
	"scope_red_dot":  {"slot": "optic", "spread_mult": 0.85, "range_add": 5.0},
	"scope_4x":       {"slot": "optic", "spread_mult": 0.55, "range_add": 25.0},
	"grip_angled":    {"slot": "grip",  "spread_mult": 0.9,  "fire_rate_mult": 1.0},
	"grip_vertical":  {"slot": "grip",  "spread_mult": 0.95, "fire_rate_mult": 0.92},
	"mag_extended":   {"slot": "mag",   "mag_size_add": 10},
	"mag_fast":       {"slot": "mag",   "reload_mult": 0.75},
}

# Current loadout: weapon_id -> {slot_name: attachment_id}
var loadout := {
	"rifle": {"optic": "scope_red_dot", "grip": "", "mag": ""},
	"pistol": {"optic": "", "grip": "", "mag": ""},
	"sniper": {"optic": "scope_4x", "grip": "", "mag": ""},
}
var equipped_weapon: String = "rifle"

# ---------------------------------------------------------------------------
# MAP / MATCH
# ---------------------------------------------------------------------------
var maps := [
	{"id": "map_dustbowl", "name": "Dustbowl Ruins", "scene": "res://scenes/Map1.tscn"},
	{"id": "map_harbor",   "name": "Harbor District", "scene": "res://scenes/Map2.tscn"},
]
var selected_map_index: int = 0
var bot_count: int = 7  # stand-in for other "players" until real netcode exists

# ---------------------------------------------------------------------------
# HELPERS
# ---------------------------------------------------------------------------
func get_effective_weapon_stats(weapon_id: String) -> Dictionary:
	var base: Dictionary = weapons[weapon_id].duplicate()
	var mods: Dictionary = loadout.get(weapon_id, {})
	for slot in mods.keys():
		var att_id: String = mods[slot]
		if att_id == "" or not attachments.has(att_id):
			continue
		var att: Dictionary = attachments[att_id]
		if att.has("spread_mult"):
			base["spread"] *= att["spread_mult"]
		if att.has("range_add"):
			base["range"] += att["range_add"]
		if att.has("fire_rate_mult"):
			base["fire_rate"] *= att["fire_rate_mult"]
		if att.has("mag_size_add"):
			base["mag_size"] += att["mag_size_add"]
		if att.has("reload_mult"):
			base["reload_time"] *= att["reload_mult"]
	return base

func get_selected_character() -> Dictionary:
	return characters[selected_character_index]
