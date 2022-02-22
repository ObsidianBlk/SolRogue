extends Node

# -------------------------------------------------------------------------
# Signals
# -------------------------------------------------------------------------
signal player_turn_started(player)
signal player_turn_ended()

# -------------------------------------------------------------------------
# Variables
# -------------------------------------------------------------------------
var _player : Actor = null

# -------------------------------------------------------------------------
# Onready Variables
# -------------------------------------------------------------------------


# -------------------------------------------------------------------------
# Override Methods
# -------------------------------------------------------------------------
func _ready() -> void:
	set_process_unhandled_input(false)

func _unhandled_input(event) -> void:
	if event.is_action_pressed("north"):
		if _player.cc("Mappable", "can_move", [RegionMap.NORTH]):
			end_turn(_player.cc("Mappable", "move", [RegionMap.NORTH]))
	elif event.is_action_pressed("south"):
		if _player.cc("Mappable", "can_move", [RegionMap.SOUTH]):
			end_turn(_player.cc("Mappable", "move", [RegionMap.SOUTH]))
	elif event.is_action_pressed("east"):
		if _player.cc("Mappable", "can_move", [RegionMap.EAST]):
			end_turn(_player.cc("Mappable", "move", [RegionMap.EAST]))
	elif event.is_action_pressed("west"):
		if _player.cc("Mappable", "can_move", [RegionMap.WEST]):
			end_turn(_player.cc("Mappable", "move", [RegionMap.WEST]))

# -------------------------------------------------------------------------
# Private Methods
# -------------------------------------------------------------------------



# -------------------------------------------------------------------------
# Public Methods
# -------------------------------------------------------------------------
func start_turn_with(player : Actor) -> void:
	#print("Checking is legit player")
	if _player == null and player != null:
		#print("Player's turn")
		_player = player
		set_process_unhandled_input(true)
		emit_signal("player_turn_started", _player)

func end_turn(time : float) -> void:
	if _player != null and time > 0.0:
		#print("Done with player")
		set_process_unhandled_input(false)
		_player.end_turn(time)
		_player = null
		emit_signal("player_turn_ended")

func players_turn() -> bool:
	return _player != null

# -------------------------------------------------------------------------
# Handler Methods
# -------------------------------------------------------------------------

