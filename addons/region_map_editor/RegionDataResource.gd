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
# Property Variables
# -------------------------------------------------------------------------
var _tile_size : int = 16
var _tile_set : TileSet = null
var _floor_sets : Array = []
var _wall_sets : Array = []
var _cells : Dictionary = {}
var _seed : int = 0

# -------------------------------------------------------------------------
# Variables
# -------------------------------------------------------------------------
var _RNG : RandomNumberGenerator = null
var _offset : Vector2 = Vector2.ZERO


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

func set_wall_sets(ws : String) -> void:
	if ws == "":
		_wall_sets.clear()
	
	var wsl : Array = ws.split(",")
	for i in range(0, wsl.size()):
		wsl[i] = wsl[i].lstrip(" \t\r\n").rstrip(" \t\r\n")
	_wall_sets = wsl

func get_wall_sets() -> String:
	if _wall_sets.size() <= 0:
		return ""
	return PoolStringArray(_wall_sets).join(",")

func get_offset() -> Vector2:
	return _offset

func set_offset(o : Vector2) -> void:
	_offset = o


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
		"wall_sets":
			return get_wall_sets()
		"seed":
			return _seed
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
		"wall_sets":
			if typeof(value) == TYPE_STRING:
				set_wall_sets(value)
			else : success = false
		"seed":
			if typeof(value) == TYPE_INT:
				_seed = value
				_RNG = RandomNumberGenerator.new()
				_RNG.seed = _seed
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
			name = "wall_sets",
			type = TYPE_STRING,
			usage = PROPERTY_USAGE_DEFAULT,
		},
		{
			name = "seed",
			type = TYPE_INT,
			usage = PROPERTY_USAGE_DEFAULT,
		},
		{
			name = "cells",
			type = TYPE_DICTIONARY,
			usage = PROPERTY_USAGE_STORAGE,
		},
	]
	return props

func _ready() -> void:
	pass


# -------------------------------------------------------------------------
# Private Methods
# -------------------------------------------------------------------------
func _CreateBlankCell() -> Dictionary:
	return {
		floor_set_id = 0,
		floor_id = 0,
		wall_set_id = 0,
		edges = 0,
	}


func _SetCellDictionary(cells : Dictionary) -> bool:
	if cells.empty():
		_cells.clear()
	else:
		var ncells : Dictionary = {}
		for key in cells.keys():
			if typeof(key) != TYPE_VECTOR2:
				return false
			var cell = cells[key]
			if typeof(cell) != TYPE_DICTIONARY:
				return false
			var ncell = _CreateBlankCell()
			if "floor_set_id" in cell:
				ncell.floor_set_id = cell.floor_set_id
			if "floor_id" in cell:
				ncell.floor_id = cell.floor_id
			if "wall_set_id" in cell:
				ncell.floor_set_id = cell.wall_set_id
			if "edges" in cell:
				ncell.edges = cell.edges
			if "merge" in cell:
				ncell.merge = cell.merge
			ncells[key] = ncell
		_cells = ncells
	emit_signal("info_changed")
	return true


func _CreateCell(position : Vector2, cell_info : Dictionary = {}) -> Dictionary:
	if not position in _cells:
		var cell = _CreateBlankCell()
		_cells[position] = cell
		
		if not cell_info.empty():
			cell.floor_set_id = cell_info.floor_set_id
			cell.floor_id = cell_info.floor_id
			cell.wall_set_id = cell_info.wall_set_id
			cell.edges = cell_info.edges
			if cell_info.has("merge"):
				var neighbor = _GetNeighborPosition(position, cell_info.merge)
				if not neighbor in _cells:
					cell["merge"] = cell_info.merge
		
		
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
func is_valid() -> bool:
	return _tile_set != null and _floor_sets.size() > 0 and _wall_sets.size() > 0

func empty() -> bool:
	return _cells.empty()


func clear() -> void:
	_cells.clear()
	emit_signal("info_changed")

func cap() -> void:
	var mcells : Array = get_merge_cells()
	for mcell in mcells:
		if not has_cell_at(_GetNeighborPosition(mcell.position, mcell.merge)):
			set_wall(mcell.position, mcell.merge, true)
	emit_signal("info_changed")


func copy_region_data_from(rdr : RegionDataResource, offset : Vector2 = Vector2.ZERO) -> bool:
	if is_valid():
		if rdr.tile_size == _tile_size and rdr.get_tile_set() == _tile_set:
			for key in rdr._cells.keys():
				var npos = key + offset
				if not npos in _cells:
					_CreateCell(npos, rdr._cells[key])
			return true
		printerr("Source region data tile set or size do not match destination.")
	return false
#			var cell = _CreateBlankCell()
#			cell.floor_set_id = rdr._cells[key].floor_set_id
#			cell.floor_id = rdr._cells[key].floor_id
#			cell.wall_set_id = rdr._cells[key].wall_set_id
#			cell.edges = rdr._cells[key].edges
#			_cells[key + offset] = cell


#func merge_region_data_source(rd_src : String, offset : Vector2 = Vector2.ZERO) -> void:
#	if ResourceLoader.exists(rd_src):
#		var res : RegionDataResource = ResourceLoader.load(rd_src, "RegionDataResource")
#		if res and res.is_valid():
#			merge_region_data(res, offset)

func merge_region_on_cell(position : Vector2, rdr : RegionDataResource) -> bool:
	if not is_valid():
		return false
	
	position = position.floor()
	if position in _cells:
		var cell = _cells[position]
		if cell.has("merge"):
			var opposite : int = _OppositeWall(cell.merge)
			var mcells = rdr.get_merge_cells(opposite)
			if mcells.size() > 0:
				var idx : int = _RNG.randi_range(0, mcells.size() - 1)
				var rpos = mcells[idx].position
				var mpos = _GetNeighborPosition(position, cell.merge) - rpos
				if copy_region_data_from(rdr, mpos):
					_cells[position].erase("merge")
					return true
	return false

func merge_region_on_random_cell(rdr : RegionDataResource) -> bool:
	if not is_valid():
		return false
	
	var mcells = get_merge_cells()
	if mcells.size() > 0:
		var idx : int = _RNG.randi_range(0, mcells.size() - 1)
		return merge_region_on_cell(mcells[idx].position, rdr)
	return false

func set_merge_cell(pos : Vector2, wall : int, enable : bool = true) -> void:
	if WALL.values().find(wall) >= 0:
		pos = pos.floor()
		var cell = _GetCell(pos)
		if cell:
			if enable:
				if is_wall_set(pos, wall):
					printerr("Wall exists in that direction. Not setting merge point.")
					return
				if has_cell_at(_GetNeighborPosition(pos, wall)):
					printerr("Neighbor cell is defined. Not setting merge point.")
					return
				cell.merge = wall
			else:
				if cell.has("merge"):
					cell.erase("merge")
			emit_signal("info_changed")


func is_merge_cell(pos : Vector2) -> bool:
	pos = pos.floor()
	if pos in _cells:
		return _cells[pos].has("merge")
	return false

func get_merge_cells(dir : int = 0) -> Array:
	var mcl : Array = []
	for key in _cells.keys():
		if _cells[key].has("merge"):
			if dir <= 0 or _cells[key].merge == dir:
				mcl.append({
					"position":key,
					"merge":_cells[key].merge,
				})
	return mcl


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

func get_wall_tile_id(pos : Vector2) -> int:
	if _tile_set != null and _wall_sets.size() > 0:
		var cell = _GetCell(pos.floor())
		if cell != null and cell.wall_set_id >= 0 and cell.wall_set_id < _wall_sets.size():
			var widx = cell.edges & 0x0F
			return _tile_set.find_tile_by_name(_wall_sets[cell.wall_set_id] + String(widx))
	return -1


func set_floor(pos : Vector2, floor_set_id : int, floor_id : int, create_if_not_exist : bool = true) -> void:
	if floor_set_id >= 0 and floor_set_id < _floor_sets.size():
		#print("Floor Set ID checks out")
		if floor_id >= 0 and floor_id < _floor_sets[floor_set_id].count:
			#print("Floor ID checks out")
			var cell = _GetCell(pos, create_if_not_exist)
			cell.floor_set_id = floor_set_id
			cell.floor_id = floor_id
			emit_signal("info_changed")

func get_floor_tile_id(pos : Vector2) -> int:
	#print("Getting floor tile ID")
	if _tile_set != null and _floor_sets.size() > 0:
		#print("We have the requisites.")
		var cell = _GetCell(pos.floor())
		if cell != null and cell.floor_set_id >= 0 and cell.floor_set_id < _floor_sets.size():
			#print("We have a cell with valid data")
			var fname = _floor_sets[cell.floor_set_id].name + String(cell.floor_id)
			#print("Looking for tile named: ", fname)
			return _tile_set.find_tile_by_name(fname)
	return -1

func generate_room(pos : Vector2, w : int, h : int, floor_set_id : int, wall_set_id : int, floor_id : int = -1) -> void:
	if w <= 0 or h <= 0:
		return
	if not (floor_set_id >= 0 and floor_set_id < _floor_sets.size() and wall_set_id >= 0 and wall_set_id < _wall_sets.size()):
		return
	
	pos = pos.floor()
	
	for j in range(0, h):
		for i in range(0, w):
			var npos = pos + Vector2(i, j)
			if not (npos in _cells):
				var fid = floor_id
				if fid < 0:
					fid = _RNG.randi_range(0, _floor_sets[floor_set_id].count -1)
				set_floor(npos, floor_set_id, fid, true)
				if j == 0:
					set_wall(npos, WALL.North, true, false)
				if j == h - 1:
					set_wall(npos, WALL.South, true, false)
				if i == 0:
					set_wall(npos, WALL.West, true, false)
				if i == w - 1:
					set_wall(npos, WALL.East, true, false)


func has_cell_at(pos : Vector2) -> bool:
	return pos.floor() in _cells

func remove_cell(pos : Vector2) -> void:
	pos = pos.floor()
	if pos in _cells:
		_cells.erase(pos)
		emit_signal("info_changed")

func get_used_cells() -> Array:
	return _cells.keys()

func get_neighboring_cell(pos : Vector2, dir : int) -> Vector2:
	return _GetNeighborPosition(pos, dir)

func get_random_cell_position() -> Vector2:
	if _cells.empty():
		return Vector2()
	var keys = _cells.keys()
	var i = _RNG.randi_range(0, keys.size() - 1)
	return keys[i]

# ws = World Space
func get_random_cell_position_ws(centered : bool = false) -> Vector2:
	var pos = get_random_cell_position() * _tile_size
	if centered:
		pos += Vector2(_tile_size * 0.5, _tile_size * 0.5)
	return pos




# -------------------------------------------------------------------------
# Handler Methods
# -------------------------------------------------------------------------

