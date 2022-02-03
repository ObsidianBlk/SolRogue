extends Resource
class_name ActorDataResource


# -------------------------------------------------------------------------
# Signals, ENUMs, and Constants
# -------------------------------------------------------------------------
signal type_changed(old_type, new_type)
signal component_added(component_name)
signal component_removed(component_name)
signal property_changed(component_name, property_name, value)
signal property_removed(component_name, property_name)

# -------------------------------------------------------------------------
# Property Variables
# -------------------------------------------------------------------------
var _actor_type = "Object"
var _actor_id = ""
var _components = {}

# -------------------------------------------------------------------------
# Variables
# -------------------------------------------------------------------------


# -------------------------------------------------------------------------
# Setters / Getters
# -------------------------------------------------------------------------
func set_actor_type(t : String) -> bool:
	t = _Trim(t)
	if t != "" and t != "Actor" and _actor_type != t:
		var _o = _actor_type
		_actor_type = t
		emit_signal("type_changed", _o, _actor_type)
		return true
	return false

func set_actor_id(id : String) -> bool:
	id = _Trim(id)
	if id != "":
		_actor_id = id
		return true
	return false

func get_actor_id() -> String:
	return _actor_id

# -------------------------------------------------------------------------
# Override Methods
# -------------------------------------------------------------------------
func _get(property : String):
	match property:
		"actor_type":
			return _actor_type
		"actor_id":
			return _actor_id
		"components":
			return _components
	return null

func _set(property : String, value) -> bool:
	var success = true
	match property:
		"actor_type":
			if typeof(value) == TYPE_STRING:
				success = set_actor_type(value)
			else : success = false
		"actor_id":
			if typeof(value) == TYPE_STRING:
				success = set_actor_id(value)
			else : success = false
		"components":
			if typeof(value) == TYPE_DICTIONARY:
				if _ValidateComponent(value):
					_components = value
				else : success = false
			else : success = false
		_:
			success = false
	
	if success:
		property_list_changed_notify()
	return success

func _get_property_list() -> Array:
	var props : Array = [
		{
			name = "actor_type",
			type = TYPE_STRING,
			usage = PROPERTY_USAGE_DEFAULT,
		},
		{
			name = "actor_id",
			type = TYPE_STRING,
			usage = PROPERTY_USAGE_DEFAULT,
		},
		{
			name = "components",
			type = TYPE_DICTIONARY,
			usage = PROPERTY_USAGE_STORAGE,
		},
	]
	return props


func _init() -> void:
	_actor_id = Utils.uuidv4()

# -------------------------------------------------------------------------
# Private Methods
# -------------------------------------------------------------------------
func _Trim(s : String) -> String:
	return s.lstrip(" \t\n\r").rstrip(" \t\n\r")

func _ValidateArray(a) -> bool:
	var vat = [TYPE_COLOR_ARRAY, TYPE_INT_ARRAY, TYPE_RAW_ARRAY, TYPE_REAL_ARRAY, \
				TYPE_STRING_ARRAY, TYPE_VECTOR2_ARRAY, TYPE_VECTOR3_ARRAY]
	if vat.find(typeof(a)) >= 0:
		return true
	
	for i in range(0, a.size()):
		if typeof(a[i]) == TYPE_OBJECT:
			return false
		if typeof(a[i]) == TYPE_DICTIONARY:
			if not _ValidateComponent(a[i]):
				return false
		if typeof(a[i]) == TYPE_ARRAY:
			if not _ValidateArray(a[i]):
				return false
	return true

func _ValidateComponent(c : Dictionary) -> bool:
	if not c.empty():
		for key in c.keys():
			if typeof(key) != TYPE_STRING:
				return false
			if typeof(c[key]) == TYPE_OBJECT:
				return false
			if typeof(c[key]) == TYPE_DICTIONARY:
				if not _ValidateComponent(c[key]):
					return false
			if typeof(c[key]) == TYPE_ARRAY:
				if not _ValidateArray(c[key]):
					return false
	return true


func _DupValue(v):
	match typeof(v):
		TYPE_DICTIONARY:
			v = _CopyDict(v)
		TYPE_ARRAY, TYPE_COLOR_ARRAY, TYPE_INT_ARRAY, TYPE_RAW_ARRAY, TYPE_REAL_ARRAY, \
				TYPE_STRING_ARRAY, TYPE_VECTOR2_ARRAY, TYPE_VECTOR3_ARRAY:
			v = _CopyArray(v)
	return v

func _CopyArray(a):
	var narr = a
	if typeof(a) != TYPE_ARRAY:
		narr = Array(a)
	else:
		for i in range(0, narr.size()):
			if typeof(narr[i]) != TYPE_OBJECT:
				narr[i] = _DupValue(narr[i])
	
	return narr

func _CopyDict(d : Dictionary) -> Dictionary:
	var _d : Dictionary = {}
	for key in d.keys():
		if typeof(d[key]) != TYPE_OBJECT:
			_d[key] = _DupValue(d[key])
	return _d

# -------------------------------------------------------------------------
# Public Methods
# -------------------------------------------------------------------------
func add_component(component_name : String, data : Dictionary, elastic : bool = false) -> void:
	if not component_name in _components and _ValidateComponent(data):
		_components[component_name] = {
			"elastic": elastic,
			"data": data
		}
		emit_signal("component_added", component_name)
	else:
		printerr("Component '", component_name, "' already assigned to ActorDataResource, '", _actor_id, "'.")

func remove_component(component_name : String) -> void:
	if component_name in _components:
		_components.erase(component_name)
		emit_signal("component_removed", component_name)

func has_component(component_name : String) -> bool:
	return component_name in _components

func get_component(component_name : String):
	if component_name in _components:
		return _DupValue(_components[component_name].data)
	return null

func is_component_elastic(component_name : String) -> bool:
	return component_name in _components and _components[component_name].elastic == true

func get_property(component_name : String, property : String):
	if component_name in _components:
		if property in _components[component_name].data:
			return _components[component_name].data[property]
	return null

func set_property(component_name : String, property : String, value) -> bool:
	if component_name in _components:
		if _components[component_name].elastic:
			_components[component_name].data[property] = value
			emit_signal("property_changed", component_name, property, value)
			return true
		elif property in _components[component_name].data:
			_components[component_name].data[property] = value
			emit_signal("property_changed", component_name, property, value)
			return true
	return false

func has_property(component_name : String, property : String) -> bool:
	return component_name in _components and property in _components[component_name].data

func del_property(component_name : String, property : String) -> bool:
	if component_name in _components and _components[component_name].elastic:
		if property in _components[component_name].data:
			_components[component_name].data.erase(property)
			emit_signal("property_removed", component_name, property)
			return true
	return false


# -------------------------------------------------------------------------
# Handler Methods
# -------------------------------------------------------------------------


