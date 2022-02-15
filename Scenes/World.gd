extends Node2D


func _ready() -> void:
	var map : RegionMap = get_node_or_null("RegionMap")
	if map:
		var actor : Actor = ActorFactory.create_actor(["Mappable"])
		actor.add_to_group("Player")
		map.add_actor_rand_pos(actor)
