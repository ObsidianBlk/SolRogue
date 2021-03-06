extends Node

# -------------------------------------------------------------------------
# Constants
# -------------------------------------------------------------------------
const ACTOR = preload("res://Objects/Actors/Actor.tscn")

const COMPONENT = {
	"Mappable": preload("res://Scripts/Components/Mappable.gd")
}


# -------------------------------------------------------------------------
# Variables
# -------------------------------------------------------------------------


# -------------------------------------------------------------------------
# Onready Variables
# -------------------------------------------------------------------------


# -------------------------------------------------------------------------
# Override Methods
# -------------------------------------------------------------------------


# -------------------------------------------------------------------------
# Private Methods
# -------------------------------------------------------------------------



# -------------------------------------------------------------------------
# Public Methods
# -------------------------------------------------------------------------
func create_actor(component_list : Array = []) -> Actor:
	var actor : Actor = ACTOR.instance()
	actor.actor_data = ActorDataResource.new()
	for component in component_list:
		var c = create_component(component)
		if c:
			actor.add_child(c)
	return actor

func create_component(component_name : String) -> Node:
	if component_name in COMPONENT:
		var n : Node = Node.new()
		n.set_script(COMPONENT[component_name])
		return n
	return null


# -------------------------------------------------------------------------
# Handler Methods
# -------------------------------------------------------------------------

