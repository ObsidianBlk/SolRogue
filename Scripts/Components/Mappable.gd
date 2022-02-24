extends "res://Scripts/Components/Component.gd"

# -------------------------------------------------------------------------
# Constants
# -------------------------------------------------------------------------
const IDENTITY : String = "Mappable"

# -------------------------------------------------------------------------
# Variables
# -------------------------------------------------------------------------
var tween_node : Tween = null
var tween_to_pos : Vector2 = Vector2.ZERO

# -------------------------------------------------------------------------
# Onready Variables
# -------------------------------------------------------------------------
func _ready() -> void:
	tween_node = Tween.new()
	add_child(tween_node)

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

func _tween_move(from_pos : Vector2, to_pos : Vector2, dur : float) -> void:
	if tween_node:
		var map : RegionMap = _get_map()
		if not map:
			return
		
		tween_to_pos = to_pos
		var from_wpos = map.map_position_to_world_space(from_pos, true)
		var to_wpos = map.map_position_to_world_space(to_pos, true)
		tween_node.interpolate_property(
			_actor, "position",
			from_wpos, to_wpos,
			dur,
			Tween.TRANS_LINEAR, Tween.EASE_IN_OUT
		)
		tween_node.start()
		yield(tween_node, "tween_all_completed")

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
	if tween_node and tween_node.is_active():
		tween_node.stop_all()
		_actor.actor_data.set_property(IDENTITY, "position", tween_to_pos)
		
	
	if can_move(dir):
		var pos = _actor.prop(IDENTITY, "position", Vector2.ZERO)
		var npos = pos
		match dir:
			RegionMap.NORTH:
				npos += Vector2.UP
			RegionMap.SOUTH:
				npos += Vector2.DOWN
			RegionMap.EAST:
				npos += Vector2.RIGHT
			RegionMap.WEST:
				npos += Vector2.LEFT
		_tween_move(pos, npos, 0.25)
		_actor.actor_data.set_property(IDENTITY, "position", npos)
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
	#print("Notified: ", value)
	if property_name == "position":
		_map_to_world()

func _on_actor_data_changed() -> void:
	if _actor:
		if _actor.actor_data == null:
			_actor._UnregisterComponentMethods(self)
		else:
			_component_enter()



