extends Node2D

var region_main : RegionDataResource = ResourceLoader.load("res://Assets/Regions/Test_Main.tres")
var region_room1 : RegionDataResource = ResourceLoader.load("res://Assets/Regions/Test_Room1.tres")
var region_room2 : RegionDataResource = ResourceLoader.load("res://Assets/Regions/Test_Room2.tres")

onready var camera = get_node("Camera")


func _ready() -> void:
	var map : RegionMap = get_node_or_null("RegionMap")
	if map:
		region_main.merge_region_on_random_cell(region_room2)
		region_main.merge_region_on_random_cell(region_room1)
		region_main.merge_region_on_random_cell(region_room1)
		region_main.merge_region_on_random_cell(region_room1)
		region_main.merge_region_on_random_cell(region_room2)
		region_main.merge_region_on_random_cell(region_room2)
		region_main.cap()
		map.region_data_resource = region_main
		
		var actor : Actor = ActorFactory.create_actor(["Mappable"])
		actor.add_to_group("Player")
		map.add_actor_rand_pos(actor)
		Scheduler.add_actor(actor)
		
		camera.target_node_path = camera.get_path_to(actor)
