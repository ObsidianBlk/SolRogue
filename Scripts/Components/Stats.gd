extends "res://Scripts/Components/Component.gd"

# -------------------------------------------------------------------------
# Constants
# -------------------------------------------------------------------------
const IDENTITY : String = "Stats"
const STATS : Array = ["str", "agl", "hth", "wil", "int"]


# -------------------------------------------------------------------------
# Component Override Methods
# -------------------------------------------------------------------------
func _component_enter() -> void:
	if _actor.actor_data == null:
		return
	
	if not _actor.actor_data.has_component(IDENTITY):
		_actor.actor_data.add_component(identify(), {
			"str": 1.0, # Strength
			"agl": 1.0, # Agility
			"hth": 1.0, # Health
			"wil": 1.0, # Will
			"int": 1.0, # Intelligence
			"c_str": 1.0,
			"c_agl": 1.0,
			"c_hth": 1.0,
			"c_wil": 1.0,
			"c_int": 1.0,
			"hp":1.0
		})
	
	_RegisterMethods([
		"set_base_stat",
		"set_stat",
		"get_stat",
		"get_max_hp",
		"hurt",
		"heal",
	])

func _component_exit() -> void:
	pass


# -------------------------------------------------------------------------
# Private Methods
# -------------------------------------------------------------------------

func set_base_stat(stat_name : String, value : float, match_current : bool = false) -> void:
	stat_name = stat_name.to_lower()
	if STATS.find(stat_name) < 0:
		return
	
	if match_current:
		var cstat_name = "c_" + stat_name
		var csvalue = _actor.prop(IDENTITY, stat_name, value)
		if csvalue > value or (csvalue < value and match_current):
			_actor.set_prop(IDENTITY, cstat_name, value)
	_actor.set_prop(IDENTITY, stat_name, value)

func set_stat(stat_name : String, value : float) -> void:
	stat_name = stat_name.to_lower()
	if STATS.find(stat_name) < 0:
		return
	var cstat_name = "c_" + stat_name
	var base_value = _actor.prop(IDENTITY, stat_name, 0.0)
	if value < base_value:
		_actor.set_prop(IDENTITY, cstat_name, value)

func get_stat(stat_name : String, base_value : bool = false) -> float:
	stat_name = stat_name.to_lower()
	if STATS.find(stat_name) < 0:
		return 0.0
	if not base_value:
		stat_name = "c_" + stat_name
	return _actor.prop(IDENTITY, stat_name, 0.0)

func get_max_hp() -> float:
	var hth = _actor.prop(IDENTITY, "c_hth", 0.0)
	var strg = _actor.prop(IDENTITY, "c_str", 0.0)
	var agl = _actor.prop(IDENTITY, "c_agl", 0.0)
	return hth * (strg + agl) * 10

func heal(amount : float) -> void:
	var hp = _actor.prop(IDENTITY, "hp", 0.0)
	var mhp = get_max_hp()
	hp = min(hp + amount, mhp)
	_actor.set_prop(IDENTITY, "hp", hp)

func hurt(amount : float) -> void:
	var hp = _actor.prop(IDENTITY, "hp", 0.0)
	hp = max(hp - amount, 0)
	_actor.set_prop(IDENTITY, "hp", hp)

# -------------------------------------------------------------------------
# Public Methods
# -------------------------------------------------------------------------
func identify() -> String:
	return IDENTITY
