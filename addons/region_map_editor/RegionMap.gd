tool
extends Node2D
class_name RegionMap

# -------------------------------------------------------------------------
# Constants
# -------------------------------------------------------------------------

const EDITOR_CELL_BODY_COLOR : Color = Color(0.0, 1.0, 0.0, 0.5)
const EDITOR_CELL_EDGE_COLOR : Color = Color(1.0, 0.8, 0.0, 0.5)

const NORTH = 0x01
const EAST = 0x02
const SOUTH = 0x04
const WEST = 0x08

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

var _room_start = null

var floor_tilemap_node : TileMap = null
var wall_tilemap_node : TileMap = null
var actor_container_node : Node2D = null


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
	floor_tilemap_node = TileMap.new()
	actor_container_node = Node2D.new()
	wall_tilemap_node = TileMap.new()
	add_child(floor_tilemap_node)
	add_child(actor_container_node)
	add_child(wall_tilemap_node)
	if region_data_resource != null:
		var cell_size = Vector2(
			region_data_resource.tile_size,
			region_data_resource.tile_size
		)
		floor_tilemap_node.cell_size = cell_size
		floor_tilemap_node.tile_set = region_data_resource.get_tile_set()
		floor_tilemap_node.show_behind_parent = true
		wall_tilemap_node.cell_size = cell_size
		wall_tilemap_node.tile_set = region_data_resource.get_tile_set()
		wall_tilemap_node.show_behind_parent = true
	if region_data_resource:
		if not Engine.editor_hint:
			region_data_resource.cap()
		else:
			_UpdateCells()
	#call_deferred("_ready_deferred")


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
			if not Input.is_key_pressed(KEY_CONTROL):
				_room_start = null
			
			if _tool_edge >= 0:
				if Input.is_key_pressed(KEY_SHIFT):
					var enable = not region_data_resource.is_merge_cell(_mouse_cell)
					region_data_resource.set_merge_cell(_mouse_cell, _tool_edge, enable)
				else:
					var enable = not region_data_resource.is_wall_set(_mouse_cell, _tool_edge)
					region_data_resource.set_wall(_mouse_cell, _tool_edge, enable)
			else:
				if Input.is_key_pressed(KEY_CONTROL):
					if _room_start == null:
						_room_start = _mouse_cell
					else:
						var s = Vector2(
							_room_start.x if _room_start.x < _mouse_cell.x else _mouse_cell.x,
							_room_start.y if _room_start.y < _mouse_cell.y else _mouse_cell.y
						)
						var e = Vector2(
							_room_start.x if _room_start.x > _mouse_cell.x else _mouse_cell.x,
							_room_start.y if _room_start.y > _mouse_cell.y else _mouse_cell.y
						)
						region_data_resource.generate_room(s, (e.x - s.x) + 1, (e.y - s.y) + 1, 0, 0)
						_room_start = null
				else:
					region_data_resource.set_floor(_mouse_cell, 0, 0)
			_UpdateCells()
		elif event.button_index == BUTTON_RIGHT and event.pressed:
			region_data_resource.remove_cell(_mouse_cell)

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
	
	if edge < 0:
		draw_rect(Rect2(pos_tl, Vector2(grid_size, grid_size)), EDITOR_CELL_EDGE_COLOR)
	if _room_start != null:
		var pos = map_position_to_world_space(_room_start)
		draw_rect(Rect2(pos, Vector2(grid_size, grid_size)), Color(0.0, 0.0, 1.0))
	_tool_draw_merge_cells()
	
	draw_line(pos_tl, pos_tr, color_n, 2.0)
	draw_line(pos_bl, pos_br, color_s, 2.0)
	draw_line(pos_tr, pos_br, color_e, 2.0)
	draw_line(pos_tl, pos_bl, color_w, 2.0)

func _tool_draw_merge_cells() -> void:
	if region_data_resource != null:
		var lines : Array = [
			[Vector2(0.0, 0.0), Vector2(0.0, -0.5)],
			[Vector2(0.0, -0.5), Vector2(-0.5, -0.25)],
			[Vector2(0.0, -0.5), Vector2(0.5, -0.25)]
		]
		var mcells = region_data_resource.get_merge_cells()
		for cell in mcells:
			var rot = 0.0
			var pos = map_position_to_world_space(cell.position) + Vector2(
				region_data_resource.tile_size * 0.5,
				region_data_resource.tile_size * 0.5
			)
			match cell.merge:
				RegionDataResource.WALL.East:
					rot = deg2rad(90)
				RegionDataResource.WALL.South:
					rot = deg2rad(180)
				RegionDataResource.WALL.West:
					rot = deg2rad(270)
			for line in lines:
				var p1 = (line[0].rotated(rot) * region_data_resource.tile_size) + pos
				var p2 = (line[1].rotated(rot) * region_data_resource.tile_size) + pos
				draw_line(p1, p2, EDITOR_CELL_EDGE_COLOR, 1.0)


func _tool_process(delta : float) -> void:
	if _tool_dirty:
		update()
		_tool_dirty = false

# -------------------------------------------------------------------------
# Private Tool Methods
# -------------------------------------------------------------------------

func _tool_find_edge(mp : Vector2, n : Vector2, s : Vector2, e : Vector2, w : Vector2, grid_size : int) -> int:
	var min_d : float = grid_size * 0.3
	var d : float = grid_size * 2
	
	_tool_edge = -1
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
	#print("Attempting Cell Update")
	if region_data_resource != null and region_data_resource.has_tile_set():
		#print("Have Tileset and Resource")
		if wall_tilemap_node != null:
			#print("There are walls")
			wall_tilemap_node.clear()
		if floor_tilemap_node != null:
			#print("There are FLOORS")
			floor_tilemap_node.clear()
		var cells = region_data_resource.get_used_cells()
		for pos in cells:
			if wall_tilemap_node != null:
				#var widx = region_data_resource.tile_set.find_tile_by_name("Wall" + String(cell.wall_id))
				var widx = region_data_resource.get_wall_tile_id(pos)
				wall_tilemap_node.set_cell(pos.x, pos.y, widx)
			if floor_tilemap_node != null:
				var fidx = region_data_resource.get_floor_tile_id(pos)
				floor_tilemap_node.set_cell(pos.x, pos.y, fidx)

func _GetActorAt(pos : Vector2) -> Array:
	var actor_list : Array = []
	if actor_container_node != null:
		for child in actor_container_node.get_children():
			if child is Actor and child.i_am("Mappable"):
				if child.prop("Mappable", "position", Vector2.ZERO) == pos:
					actor_list.append(child)
	return actor_list

# -------------------------------------------------------------------------
# Public Methods
# -------------------------------------------------------------------------
func add_actor(actor : Actor) -> void:
	if actor_container_node == null:
		return
	
	if actor.actor_data != null and actor.actor_data.has_component("Mappable"):
		var actor_position = actor.prop("Mappable", "position", Vector2.ZERO)
		var parent = actor.get_parent()
		if parent:
			if parent == actor_container_node:
				return
			parent.remove_child(actor)
		actor_container_node.add_child(actor)
		actor.position = map_position_to_world_space(actor_position, true)

func add_actor_rand_pos(actor : Actor) -> void:
	if actor_container_node == null:
		return
	
	if actor.actor_data != null and actor.actor_data.has_component("Mappable"):
		var parent = actor.get_parent()
		if parent:
			if parent == actor_container_node:
				return
			parent.remove_child(actor)
		actor_container_node.add_child(actor)
		var actor_position = region_data_resource.get_random_cell_position()
		actor.actor_data.set_property("Mappable", "position", actor_position)
		#actor.position = map_position_to_world_space(actor_position, true)

func remove_actor(actor : Actor) -> void:
	if actor_container_node:
		return
	
	var parent = actor.get_parent()
	if parent == actor_container_node:
		parent.remove_child(actor)

func get_actors() -> Array:
	return get_tree().get_nodes_in_group("Actor")

func get_actors_ex(in_group_list : Array = [], out_group_list : Array = []) -> Array:
	if in_group_list.size() <= 0 and out_group_list.size() <= 0:
		return get_actors()
	
	var garr : Array = []
	if in_group_list.size() > 0:
		for group in in_group_list:
			garr.append_array(get_tree().get_nodes_in_group(group))
		
		var t = []
		for item in garr:
			if item.is_in_group("Actor"):
				t.append(item)
		garr = t
	
	if out_group_list.size() > 0:
		if garr.size() <= 0:
			garr = get_actors()
		
		var t = []
		for item in garr:
			var additem = true
			for group in out_group_list:
				if item.is_in_group(group):
					additem = false
					break
			if additem:
				t.append(item)
		garr = t
	
	return garr


func get_player_start() -> Vector2:
	if region_data_resource != null:
		return region_data_resource.get_random_cell_position()
	return Vector2(0, 0)

func can_move(pos : Vector2, dir : int) -> bool:
	if region_data_resource != null and [NORTH, EAST, SOUTH, WEST].find(dir) >= 0:
		if not region_data_resource.is_wall_set(pos, dir):
			var npos = region_data_resource.get_neighboring_cell(pos, dir)
			var actors = _GetActorAt(npos)
			if actors.size() > 0:
				for actor in actors:
					if actor.prop("Mappable", "blocking", false):
						return false
			return true
	return false

func position_to_map_space(pos : Vector2) -> Vector2:
	if region_data_resource != null:
		pos = pos / region_data_resource.tile_size
		pos = pos.floor()
	return pos

func map_position_to_world_space(pos : Vector2, centered : bool = false) -> Vector2:
	if region_data_resource != null:
		pos = pos * region_data_resource.tile_size
		if centered:
			pos += Vector2(region_data_resource.tile_size * 0.5, region_data_resource.tile_size * 0.5)
	return pos

# -------------------------------------------------------------------------
# Handler Methods
# -------------------------------------------------------------------------
func _on_resource_info_changed() -> void:
	_UpdateCells()
	_tool_dirty = true



