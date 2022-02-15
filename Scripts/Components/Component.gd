extends Node
class_name Component


# -------------------------------------------------------------------------
# Variables
# -------------------------------------------------------------------------
var _actor : Actor = null

# -------------------------------------------------------------------------
# Onready Variables
# -------------------------------------------------------------------------


# -------------------------------------------------------------------------
# Override Methods
# -------------------------------------------------------------------------
func _ready() -> void:
	pass


func _enter_tree() -> void:
	var parent = get_parent()
	if not parent is Actor:
		printerr("Component '", identify(), "' is not connected to an Actor node.")
		parent.remove_child(self)
		queue_free()
		return
	_actor = parent
	if not _actor.is_connected("actor_data_changed", self, "_on_actor_data_changed"):
		_actor.connect("actor_data_changed", self, "_on_actor_data_changed")
	_component_enter()

func _exit_tree() -> void:
	_component_exit()

# -------------------------------------------------------------------------
# Private Methods
# -------------------------------------------------------------------------
func _force_trigger() -> void:
	_enter_tree()

func _component_enter() -> void:
	pass

func _component_exit() -> void:
	pass

func _RegisterMethods(methods : Array) -> void:
	if _actor:
		for method in methods:
			if typeof(method) == TYPE_STRING:
				_actor._RegisterComponentMethod(self, method)

# -------------------------------------------------------------------------
# Public Methods
# -------------------------------------------------------------------------
func identify() -> String:
	return "Component"

func notify_property_changed(property_name : String, value) -> void:
	pass

# -------------------------------------------------------------------------
# Handler Methods
# -------------------------------------------------------------------------
func _on_actor_data_changed() -> void:
	pass

