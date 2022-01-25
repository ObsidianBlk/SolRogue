extends Resource
tool
class_name RegionDataResource

# -------------------------------------------------------------------------
# Constants
# -------------------------------------------------------------------------
enum WALL {
	North = 0x01,
	East = 0x02,
	South = 0x04,
	West = 0x08,
}

enum CORNER {
	NW = 0x10,
	NE = 0x20,
	SE = 0x40,
	SW = 0x50,
}

# -------------------------------------------------------------------------
# Signals
# -------------------------------------------------------------------------
signal info_changed

# -------------------------------------------------------------------------
# Variables
# -------------------------------------------------------------------------
var _tile_size : int = 16
var _tile_set : TileSet = null
var _floor_sets : Array = []
var _wall_sets : Array = []
var _cells : Dictionary = {}


# -------------------------------------------------------------------------
# Setters / Getters
# -------------------------------------------------------------------------
func set_tile_set(ts : TileSet) -> void:
	_tile_set = ts
	emit_signal("info_changed")

func get_tile_set() -> TileSet:
	return _tile_set

func has_tile_set() -> bool:
	return _tile_set != null

func set_floor_sets(fs : String) -> void:
	if fs == "":
		_floor_sets.clear()
		return
	
	var fsl : Array = fs.split(",")
	if fsl.size() % 2 > 0:
		return
	
	var new_floor_sets : Array = []
	var parsing_name : bool = true
	
	var floor_name : String = ""
	var floor_count : int = 0
	for item in fsl:
		if parsing_name:
			floor_name = item.lstrip(" \t\r\n").rstrip(" \t\r\n")
			if floor_name == "":
				return
		else:
			if not item.is_valid_integer():
				return
			floor_count = item.to_int()
			if floor_count <= 0:
				return
		
		if not parsing_name:
			new_floor_sets.append({
				"name": floor_name,
				"count": floor_count
			})
		parsing_name = !parsing_name
	
	_floor_sets = new_floor_sets

func get_floor_sets() -> String:
	if _floor_sets.size() <= 0:
		return ""
	var v = ""
	for item in _floor_sets:
		if v != "":
			v += ","
		v += item.name + "," + String(item.count)
	return v


# -------------------------------------------------------------------------
# Override Methods
# -------------------------------------------------------------------------

func _get(property : String):
	match property:
		"tile_size":
			return _tile_size
		"tile_set":
			return _tile_set
		"floor_sets":
			return get_floor_sets()
		"cells":
			return _cells
	return null


func _set(property : String, value) -> bool:
	var success = true
	match property:
		"tile_size":
			if typeof(value) == TYPE_INT and value > 0 and value <= 1024:
				if _tile_size != value:
					_tile_size = value
					emit_signal("info_changed")
			else : success = false
		"tile_set":
			if value == null or value is TileSet:
				_tile_set = value
				emit_signal("info_changed")
			else : success = false
		"floor_sets":
			if typeof(value) == TYPE_STRING:
				set_floor_sets(value)
			else : success = false
		"cells":
			if typeof(value) == TYPE_DICTIONARY:
				_SetCellDictionary(value)
			else : success = false
		_:
			success = false
	
	if success:
		property_list_changed_notify()
	return success

func _get_property_list() -> Array:
	var props = [
		{
			name = "tile_size",
			type = TYPE_INT,
			usage = PROPERTY_USAGE_DEFAULT,
		},
		{
			name = "tile_set",
			type = TYPE_OBJECT,
			hint = PROPERTY_HINT_RESOURCE_TYPE,
			hint_string = "TileSet",
			usage = PROPERTY_USAGE_DEFAULT,
		},
		{
			name = "floor_sets",
			type = TYPE_STRING,
			usage = PROPERTY_USAGE_DEFAULT,
		},
		{
			name = "cells",
			type = TYPE_DICTIONARY,
			usage = PROPERTY_USAGE_STORAGE,
		}
	]
	return props

func _ready() -> void:
	print("The cells are: ", _cells)


# -------------------------------------------------------------------------
# Private Methods
# -------------------------------------------------------------------------
func _SetCellDictionary(cells : Dictionary) -> bool:
	_cells = cells
	emit_signal("info_changed")
	return true


func _CreateCell(position : Vector2) -> Dictionary:
	if not position in _cells:
		var cell = {
			floor_id = -1,
			edges = 0
		}
		_cells[position] = cell
		
		var npos = _GetNeighborPosition(position, WALL.North)
		var ncell = _GetCell(npos)
		if ncell != null:
			if (ncell.edges & WALL.South) == WALL.South:
				cell.edges = cell.edges | WALL.North
		
		npos = _GetNeighborPosition(position, WALL.East)
		ncell = _GetCell(npos)
		if ncell != null:
			if (ncell.edges & WALL.West) == WALL.West:
				cell.edges = cell.edges | WALL.East
		
		npos = _GetNeighborPosition(position, WALL.South)
		ncell = _GetCell(npos)
		if ncell != null:
			if (ncell.edges & WALL.North) == WALL.North:
				cell.edges = cell.edges | WALL.South
		
		npos = _GetNeighborPosition(position, WALL.West)
		ncell = _GetCell(npos)
		if ncell != null:
			if (ncell.edges & WALL.East) == WALL.East:
				cell.edges = cell.edges | WALL.West

	return _cells[position]


func _GetCell(position : Vector2, create_if_not_exist : bool = false):
	if position in _cells:
		return _cells[position]
	if create_if_not_exist:
		return _CreateCell(position)
	return null


func _GetNeighborPosition(position : Vector2, wall : int) -> Vector2:
	var npos : Vector2 = Vector2()
	match wall:
		WALL.North:
			npos = position + Vector2.UP
		WALL.East:
			npos = position + Vector2.RIGHT
		WALL.South:
			npos = position + Vector2.DOWN
		WALL.West:
			npos = position + Vector2.LEFT
	return npos


func _OppositeWall(wall : int) -> int:
	match wall:
		WALL.North:
			return WALL.South
		WALL.East:
			return WALL.West
		WALL.South:
			return WALL.North
		WALL.West:
			return WALL.East
	return -1

func _CornerWalls(corner : int) -> Array:
	match corner:
		CORNER.NW:
			return [WALL.North, WALL.West]
		CORNER.NE:
			return [WALL.North, WALL.East]
		CORNER.SE:
			return [WALL.South, WALL.East]
		CORNER.SW:
			return [WALL.South, WALL.West]
	return []

func _SetWall(cell : Dictionary, wall : int, enable : bool) -> void:
	if enable:
		cell.edges = cell.edges | wall
	else:
		cell.edges = cell.edges & (~wall)

# -------------------------------------------------------------------------
# Public Methods
# -------------------------------------------------------------------------
func set_wall(pos : Vector2, wall : int, enable : bool = true, create_if_not_exist : bool = true) -> void:
	if WALL.values().find(wall) >= 0:
		pos = pos.floor()
		var npos = _GetNeighborPosition(pos, wall)
		
		var cell = _GetCell(pos, create_if_not_exist)
		_SetWall(cell, wall, enable)
		
		var ncell = _GetCell(npos)
		if ncell != null:
			var owall = _OppositeWall(wall)
			_SetWall(ncell, owall, enable)


func is_wall_set(pos : Vector2, wall : int) -> bool:
	if WALL.values().find(wall) >= 0:
		var cell = _GetCell(pos.floor())
		if cell != null:
			return (cell.edges & wall) == wall
	return false

func get_wall_id_at(pos : Vector2) -> int:
	var cell = _GetCell(pos.floor())
	if cell != null:
		return cell.edges & 0x0F
	return 0

func get_wall_tile_id(tile_base_name : String, wall_id : int) -> int:
	if _tile_set != null:
		return _tile_set.find_tile_by_name(tile_base_name + String(wall_id))
	return -1

func get_cells() -> Array:
	var walls : Array = []
	for pos in _cells.keys():
		var cell = _cells[pos]
		walls.append({
			"position":pos,
			"floor_id":cell.floor_id,
			"wall_id":cell.edges & 0x0f,
		})	
	return walls

# -------------------------------------------------------------------------
# Handler Methods
# -------------------------------------------------------------------------

