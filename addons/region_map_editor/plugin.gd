tool
extends EditorPlugin


var current_resource : RegionMap = null


func _enter_tree():
	pass

func _exit_tree():
	pass

func edit(object):
	if object is RegionMap:
		current_resource = object

func handles(object):
	return object is RegionMap

func forward_canvas_gui_input(event):
	if current_resource != null:
		current_resource._tool_unhandled_input(event)
