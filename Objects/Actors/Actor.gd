extends Node2D
class_name Actor


# -------------------------------------------------------------------------
# Signals
# -------------------------------------------------------------------------
signal actor_data_changed()
signal turn_ended(time_used, actor)

# -------------------------------------------------------------------------
# Constants
# -------------------------------------------------------------------------

const AI_METHOD_NAME : String = "process_ai"

# -------------------------------------------------------------------------
# Export Variables
# -------------------------------------------------------------------------
export var actor_data : Resource = null				setget set_actor_data

# -------------------------------------------------------------------------
# Variables
# -------------------------------------------------------------------------
var _component_methods = {}

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
			actor_data.disconnect("component_added", self, "_on_component_added")
			actor_data.disconnect("component_removed", self, "_on_component_removed")
			actor_data.disconnect("property_changed", self, "_on_property_changed")
			actor_data.disconnect("property_removed", self, "_on_property_removed")
		actor_data = r
		if actor_data != null:
			actor_data.connect("type_changed", self, "_on_actor_type_changed")
			actor_data.connect("component_added", self, "_on_component_added")
			actor_data.connect("component_removed", self, "_on_component_removed")
			actor_data.connect("property_changed", self, "_on_property_changed")
			actor_data.connect("property_removed", self, "_on_property_removed")
			add_to_group(actor_data.get_actor_type())
		emit_signal("actor_data_changed")

# -------------------------------------------------------------------------
# Override Methods
# -------------------------------------------------------------------------
func _ready() -> void:
	pass

func add_child(n : Node, legible_unique_name : bool = false) -> void:
	.add_child(n, legible_unique_name)
	if n.has_method("activate_component"):
		n.activate_component()

func remove_child(n : Node) -> void:
	if n.has_method("deactivate_component"):
		n.deactivate_component()
	.remove_child(n)


# -------------------------------------------------------------------------
# Private Methods
# -------------------------------------------------------------------------
func _RegisterComponentMethod(component : Node, method : String) -> void:
	if not component.has_method("identify"):
		return
	
	var cname = component.identify()
	if not cname in _component_methods:
		_component_methods[cname] = {
			"node": component,
			"method": []
		}
	if _component_methods[cname].method.find(method) < 0:
		_component_methods[cname].method.append(method)


func _UnregisterComponentMethods(component : Node) -> void:
	if not component.has_method("identify"):
		return
	
	var cname = component.identify()
	if cname in _component_methods:
		_component_methods.erase(cname)


func _RemoveComponent(component_name : String) -> void:
	for child in get_children():
		if child.has_method("_component_exit"):
			remove_child(child)
			child.queue_free()


func _FindAI(): # Retuns Dictionary or Null
	for cname in _component_methods:
		if _component_methods[cname].method.find(AI_METHOD_NAME) >= 0:
			return {"cname": cname, "method":AI_METHOD_NAME}
	return null

# -------------------------------------------------------------------------
# Public Methods
# -------------------------------------------------------------------------
func get_id() -> String:
	if actor_data != null:
		return actor_data.get_actor_id()
	return ""


func i_am(component_name : String) -> bool:
	return actor_data != null and actor_data.has_component(component_name)

func prop(component_name : String, property_name : String, default_value = null):
	if actor_data:
		return actor_data.get_property(component_name, property_name)
	return default_value

func set_prop(component_name : String, property_name : String, value) -> void:
	if actor_data:
		actor_data.set_property(component_name, property_name, value)

func cc(component_name : String, method : String, args : Array = [], default_value = null):
	if component_name in _component_methods:
		var cinfo = _component_methods[component_name]
		if cinfo.method.find(method) >= 0:
			return cinfo.node.callv(method, args)
	return default_value

func get_area_light() -> Light2D:
	var light : Light2D = get_node_or_null("Light_Area")
	return light

func end_turn(time : float) -> void:
	emit_signal("turn_ended", time, self)

func start_turn() -> void:
	var ai = _FindAI()
	var time : float = 0.1
	if ai != null:
		time = cc(ai.cname, ai.method)
	emit_signal("turn_ended", time, self)


# -------------------------------------------------------------------------
# Handler Methods
# -------------------------------------------------------------------------
func _on_actor_type_changed(old_type : String, new_type : String) -> void:
	if is_in_group(old_type):
		remove_from_group(old_type)
	if not is_in_group(new_type):
		add_to_group(new_type)

func _on_component_added(component_name : String) -> void:
	var n : Node = ActorFactory.create_component(component_name)
	if n != null:
		add_child(n)

func _on_component_removed(component_name : String) -> void:
	_RemoveComponent(component_name)

func _on_property_changed(component_name : String, property_name : String, value) -> void:
	for child in get_children():
		if child.has_method("identify"):
			if child.identify() == component_name:
				child._on_property_changed(property_name, value)

func _on_property_removed(component_name : String, property_name : String) -> void:
	pass

