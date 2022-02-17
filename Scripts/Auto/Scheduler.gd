extends Node

# -------------------------------------------------------------------------
# Export Variables
# -------------------------------------------------------------------------


# -------------------------------------------------------------------------
# Variables
# -------------------------------------------------------------------------
var _actors : Dictionary = {}
var _sched : Array = []
var _turn_active : bool = false

# -------------------------------------------------------------------------
# Onready Variables
# -------------------------------------------------------------------------


# -------------------------------------------------------------------------
# Override Methods
# -------------------------------------------------------------------------

func _process(_delta : float) -> void:
	if not _turn_active:
		if _sched.size() > 0:
			var info = _sched.pop_front()
			if info.name in _actors:
				_turn_active = true
				var actor : Actor = _actors[info.name]
				if actor.is_in_group("Player"):
					PlayerContoller.start_turn_with(actor)
				else:
					actor.start_turn()

# -------------------------------------------------------------------------
# Private Methods
# -------------------------------------------------------------------------
func _AddToScheduler(actor_name : String, time : float) -> void:
	if actor_name in _actors:
		var entry = {"name":actor_name, "time":time}
		for i in range(0, _sched.size()):
			if _sched[i].name == actor_name:
				return # Actor already scheduled
			if _sched[i].time > time:
				_sched.insert(i, entry)
				return
		_sched.append(entry)


# -------------------------------------------------------------------------
# Public Methods
# -------------------------------------------------------------------------
func add_actor(actor : Actor) -> void:
	if not actor.name in _actors:
		_actors[actor.name] = actor
		_AddToScheduler(actor.name, 0.0)
		actor.connect("turn_ended", self, "_on_actor_turn_ended")

# -------------------------------------------------------------------------
# Handler Methods
# -------------------------------------------------------------------------
func _on_actor_turn_ended(time : float, actor : Actor) -> void:
	_turn_active = false
	if actor.name in _actors:
		if time > 0.0:
			_AddToScheduler(actor.name, time)
		else:
			_actors.erase(actor.name)

