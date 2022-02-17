extends "res://Scripts/Components/Component.gd"

# -------------------------------------------------------------------------
# Constants
# -------------------------------------------------------------------------
const IDENTITY : String = "Mappable"

# -------------------------------------------------------------------------
# Variables
# -------------------------------------------------------------------------

# -------------------------------------------------------------------------
# Onready Variables
# -------------------------------------------------------------------------


# -------------------------------------------------------------------------
# Component Override Methods
# -------------------------------------------------------------------------
func _component_enter() -> void:
	if _actor.actor_data == null:
		return
	
	if not _actor.actor_data.has_component(IDENTITY):
		_actor.actor_data.add_component(identify(), {
			"position": Vector2.ZERO,
			"speed": 1.0,
			"blocking": true,
		})
	
	_RegisterMethods([
		"can_move",
		"move",
		"is_blocking",
	])

func _component_exit() -> void:
	pass


# -------------------------------------------------------------------------
# Private Methods
# -------------------------------------------------------------------------
func _get_map() -> RegionMap:
	var parent = _actor.get_parent()
	if parent:
		parent = parent.get_parent()
		if parent is RegionMap:
			return parent
	return null

func _map_to_world() -> void:
	var map : RegionMap = _get_map()
	if map:
		var pos = map.map_position_to_world_space(_actor.actor_data.get_property(IDENTITY, "position"), true)
		_actor.position = pos

# -------------------------------------------------------------------------
# Public Methods
# -------------------------------------------------------------------------
func identify() -> String:
	return IDENTITY

func can_move(dir : int) -> bool:
	var map : RegionMap = _get_map()
	if map:
		return map.can_move(_actor.prop(IDENTITY, "position", Vector2.ZERO), dir)
	return false

func move(dir : int) -> float:
	if can_move(dir):
		var pos = _actor.prop(IDENTITY, "position", Vector2.ZERO)
		match dir:
			RegionMap.NORTH:
				pos += Vector2.UP
			RegionMap.SOUTH:
				pos += Vector2.DOWN
			RegionMap.EAST:
				pos += Vector2.RIGHT
			RegionMap.WEST:
				pos += Vector2.LEFT
		_actor.actor_data.set_property(IDENTITY, "position", pos)
		return _actor.prop(IDENTITY, "speed", 0.0)
	return 0.0

func is_blocking() -> bool:
	if _actor != null:
		return _actor.prop(IDENTITY, "blocking", false)
	return false

# -------------------------------------------------------------------------
# Handler Methods
# -------------------------------------------------------------------------

func _on_property_changed(property_name : String, value) -> void:
	print("Notified: ", value)
	if property_name == "position":
		_map_to_world()

func _on_actor_data_changed() -> void:
	if _actor:
		if _actor.actor_data == null:
			_actor._UnregisterComponentMethods(self)
		else:
			_component_enter()



