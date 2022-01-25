tool
extends Node2D
class_name RegionMap

# -------------------------------------------------------------------------
# Constants
# -------------------------------------------------------------------------

const EDITOR_CELL_BODY_COLOR : Color = Color(0.0, 1.0, 0.0, 0.5)
const EDITOR_CELL_EDGE_COLOR : Color = Color(1.0, 0.8, 0.0, 0.5)

# -------------------------------------------------------------------------
# Export Variables
# -------------------------------------------------------------------------
export (Resource) var region_data_resource = null		setget set_region_data_resource

# -------------------------------------------------------------------------
# Variables
# -------------------------------------------------------------------------
var _tool_dirty : bool = true
var _tool_edge : int = -1
var _last_mouse_pos : Vector2 = Vector2()
var _mouse_cell : Vector2 = Vector2()

var floor_tilemap_node : TileMap = null
var wall_tilemap_node : TileMap = null


# -------------------------------------------------------------------------
# Setters / Getters
# -------------------------------------------------------------------------
func set_region_data_resource(res : Resource) -> void:
	if (res == null or res is RegionDataResource) and res != region_data_resource:
		if region_data_resource != null:
			region_data_resource.disconnect("info_changed", self, "_on_resource_info_changed")
		region_data_resource = res
		if region_data_resource != null:
			if not region_data_resource.is_connected("info_changed", self, "_on_resource_info_changed"):
				region_data_resource.connect("info_changed", self, "_on_resource_info_changed")
			var cell_size = Vector2(
				region_data_resource.tile_size,
				region_data_resource.tile_size
			)
			if floor_tilemap_node != null:
				floor_tilemap_node.cell_size = cell_size
				floor_tilemap_node.tile_set = region_data_resource.get_tile_set()
			if wall_tilemap_node != null:
				wall_tilemap_node.cell_size = cell_size
				wall_tilemap_node.tile_set = region_data_resource.get_tile_set()
			call_deferred("_UpdateCells")


# -------------------------------------------------------------------------
# Override Methods
# -------------------------------------------------------------------------
func _ready() -> void:
	call_deferred("_ready_deferred")


func _draw() -> void:
	if Engine.editor_hint:
		_tool_draw()

func _process(delta : float) -> void:
	if Engine.editor_hint:
		_tool_process(delta)


# -------------------------------------------------------------------------
# Private Tool Override Methods
# -------------------------------------------------------------------------
func _tool_unhandled_input(event) -> void:
	# NOTE: This method is called directly by the Region Map Editor plugin.
	if event is InputEventMouseMotion:
		_last_mouse_pos = get_viewport().get_mouse_position()
		if region_data_resource != null:
			_mouse_cell = (_last_mouse_pos / float(region_data_resource.tile_size)).floor()
		#_last_mouse_pos = event.position
		_tool_dirty = true
	elif event is InputEventMouseButton and region_data_resource != null:
		if event.button_index == BUTTON_LEFT and event.pressed:
			var enable = not region_data_resource.is_wall_set(_mouse_cell, _tool_edge)
			region_data_resource.set_wall(_mouse_cell, _tool_edge, enable)
			_UpdateCells()

func _tool_draw() -> void:
	if region_data_resource == null:
		return
	
	var grid_size : int = region_data_resource.tile_size
	var pos_tl : Vector2 = _mouse_cell * grid_size
	var pos_bl : Vector2 = pos_tl + (Vector2.DOWN * grid_size)
	var pos_tr : Vector2 = pos_tl + (Vector2.RIGHT * grid_size)
	var pos_br : Vector2 = pos_bl + (Vector2.RIGHT * grid_size)
	
	var edge : int = _tool_find_edge(
		_last_mouse_pos,
		pos_tl + (Vector2.RIGHT * (grid_size * 0.5)),
		pos_bl + (Vector2.RIGHT * (grid_size * 0.5)),
		pos_tr + (Vector2.DOWN * (grid_size * 0.5)),
		pos_tl + (Vector2.DOWN * (grid_size * 0.5)),
		grid_size
	)
	
	var color_n : Color = EDITOR_CELL_EDGE_COLOR if edge == RegionDataResource.WALL.North else EDITOR_CELL_BODY_COLOR
	var color_s : Color = EDITOR_CELL_EDGE_COLOR if edge == RegionDataResource.WALL.South else EDITOR_CELL_BODY_COLOR
	var color_e : Color = EDITOR_CELL_EDGE_COLOR if edge == RegionDataResource.WALL.East else EDITOR_CELL_BODY_COLOR
	var color_w : Color = EDITOR_CELL_EDGE_COLOR if edge == RegionDataResource.WALL.West else EDITOR_CELL_BODY_COLOR
	
	draw_line(pos_tl, pos_tr, color_n, 2.0)
	draw_line(pos_bl, pos_br, color_s, 2.0)
	draw_line(pos_tr, pos_br, color_e, 2.0)
	draw_line(pos_tl, pos_bl, color_w, 2.0)
	
	
	#draw_rect(Rect2(pos, Vector2(grid_size, grid_size)), EDITOR_CELL_BODY_COLOR, false, 2.0)


func _tool_process(delta : float) -> void:
	if _tool_dirty:
		update()
		_tool_dirty = false

# -------------------------------------------------------------------------
# Private Tool Methods
# -------------------------------------------------------------------------
func _ready_deferred() -> void:
	floor_tilemap_node = TileMap.new()
	wall_tilemap_node = TileMap.new()
	add_child(floor_tilemap_node)
	add_child(wall_tilemap_node)
	if region_data_resource != null:
		var cell_size = Vector2(
			region_data_resource.tile_size,
			region_data_resource.tile_size
		)
		floor_tilemap_node.cell_size = cell_size
		floor_tilemap_node.tile_set = region_data_resource.get_tile_set()
		wall_tilemap_node.cell_size = cell_size
		wall_tilemap_node.tile_set = region_data_resource.get_tile_set()
	if region_data_resource:
		_UpdateCells()


func _tool_find_edge(mp : Vector2, n : Vector2, s : Vector2, e : Vector2, w : Vector2, grid_size : int) -> int:
	var min_d : float = grid_size * 0.3
	var d : float = grid_size * 2
	
	var _d = mp.distance_to(n)
	if _d < min_d and _d < d:
		d = _d
		_tool_edge = RegionDataResource.WALL.North
	
	_d = mp.distance_to(s)
	if _d < min_d and _d < d:
		d = _d
		_tool_edge = RegionDataResource.WALL.South
	
	_d = mp.distance_to(e)
	if _d < min_d and _d < d:
		d = _d
		_tool_edge = RegionDataResource.WALL.East
	
	_d = mp.distance_to(w)
	if _d < min_d and _d < d:
		d = _d
		_tool_edge = RegionDataResource.WALL.West
	
	return _tool_edge


# -------------------------------------------------------------------------
# Private Methods
# -------------------------------------------------------------------------
func _UpdateCells() -> void:
	print("Attempting Cell Update")
	if region_data_resource != null and region_data_resource.has_tile_set():
		print("Have Tileset and Resource")
		if wall_tilemap_node != null:
			print("There are walls")
			wall_tilemap_node.clear()
		var cells = region_data_resource.get_cells()
		for cell in cells:
			if wall_tilemap_node != null:
				#var widx = region_data_resource.tile_set.find_tile_by_name("Wall" + String(cell.wall_id))
				var widx = region_data_resource.get_wall_tile_id("Wall", cell.wall_id)
				wall_tilemap_node.set_cell(cell.position.x, cell.position.y, widx)

# -------------------------------------------------------------------------
# Public Methods
# -------------------------------------------------------------------------


# -------------------------------------------------------------------------
# Handler Methods
# -------------------------------------------------------------------------
func _on_resource_info_changed() -> void:
	_UpdateCells()


