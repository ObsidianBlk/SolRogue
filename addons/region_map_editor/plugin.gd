tool
extends EditorPlugin


var current_resource : RegionMap


func _enter_tree():
	pass

func _exit_tree():
	pass

func edit(object):
	if object is RegionMap:
		current_resource = object

func handles(object):
	return object is RegionMap

func make_visible(visible):
	if visible == false:
		current_resource = null


func forward_canvas_gui_input(event):
	if current_resource != null:
		return current_resource._tool_unhandled_input(event)
		#return true
