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
# Exports
# -------------------------------------------------------------------------
export var texture : Texture = null				setget set_texture
export (int, 2, 1024, 1) var tile_size = 16

# -------------------------------------------------------------------------
# Variables
# -------------------------------------------------------------------------
var _cells = {}

# -------------------------------------------------------------------------
# Setters / Getters
# -------------------------------------------------------------------------
func set_texture (t : Texture) -> void:
	if texture != t:
		texture = t
		emit_signal("info_changed")

func set_tile_size (s : int) -> void:
	if s > 0 and s <= 1024 and s != tile_size:
		tile_size = s
		emit_signal("info_changed")


# -------------------------------------------------------------------------
# Override Methods
# -------------------------------------------------------------------------


# -------------------------------------------------------------------------
# Private Methods
# -------------------------------------------------------------------------
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
			npos = position + Vector2.DOWN
		WALL.East:
			npos = position + Vector2.LEFT
		WALL.South:
			npos = position + Vector2.UP
		WALL.West:
			npos = position + Vector2.RIGHT
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

# -------------------------------------------------------------------------
# Handler Methods
# -------------------------------------------------------------------------

