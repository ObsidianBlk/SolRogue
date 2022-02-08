extends Node2D
class_name Actor


# -------------------------------------------------------------------------
# Export Variables
# -------------------------------------------------------------------------
export var actor_data : Resource = null				setget set_actor_data

# -------------------------------------------------------------------------
# Variables
# -------------------------------------------------------------------------


# -------------------------------------------------------------------------
# Onready Variables
# -------------------------------------------------------------------------


# -------------------------------------------------------------------------
# Setters / Getters
# -------------------------------------------------------------------------
func set_actor_data(r : ActorDataResource) -> void:
	if r != actor_data:
		if actor_data != null:
			remove_from_group(actor_data.get_actor_type())
			actor_data.disconnect("type_changed", self, "_on_actor_type_changed")
			actor_data.disconnect("component_changed", self, "_on_component_changed")
			actor_data.disconnect("component_removed", self, "_on_component_removed")
			actor_data.disconnect("property_changed", self, "_on_property_changed")
			actor_data.disconnect("property_removed", self, "_on_property_removed")
		actor_data = r
		if actor_data != null:
			actor_data.connect("type_changed", self, "_on_actor_type_changed")
			actor_data.connect("component_changed", self, "_on_component_changed")
			actor_data.connect("component_removed", self, "_on_component_removed")
			actor_data.connect("property_changed", self, "_on_property_changed")
			actor_data.connect("property_removed", self, "_on_property_removed")
			add_to_group(actor_data.get_actor_type())

# -------------------------------------------------------------------------
# Override Methods
# -------------------------------------------------------------------------

# -------------------------------------------------------------------------
# Semi-Private Methods (to be used by child classes/nodes)
# -------------------------------------------------------------------------
func _initalize() -> void:
	if not is_in_group("Actor"):
		add_to_group("Actor")
	if actor_data != null:
		var atype = actor_data.get_actor_type()
		if not is_in_group(atype):
			add_to_group(atype)

# -------------------------------------------------------------------------
# Private Methods
# -------------------------------------------------------------------------



# -------------------------------------------------------------------------
# Public Methods
# -------------------------------------------------------------------------
func actor_class() -> String:
	return "Actor"

func get_id() -> String:
	if actor_data != null:
		return actor_data.get_actor_id()
	return ""


# -------------------------------------------------------------------------
# Handler Methods
# -------------------------------------------------------------------------
func _on_actor_type_changed(old_type : String, new_type : String) -> void:
	if is_in_group(old_type):
		remove_from_group(old_type)
	if not is_in_group(new_type):
		add_to_group(new_type)

func _on_component_added(component_name : String) -> void:
	pass

func _on_component_removed(component_name : String) -> void:
	pass

func _on_property_changed(component_name : String, property_name : String, value) -> void:
	pass

func _on_property_removed(component_name : String, property_name : String) -> void:
	pass

