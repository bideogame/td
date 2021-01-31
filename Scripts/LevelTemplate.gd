extends Node2D


onready var Map = $MapTemplate

const N = 1
const E = 2
const S = 4
const W = 8

var road_connects = {Vector2(0, -1): N, Vector2(1, 0): E, 
					Vector2(0, 1): S, Vector2(-1, 0): W}

var astar = AStar.new()
const top_margin = 2
const bottom_margin = 3
var start_point
var end_point
var path_final
var a_obs_num = 5
var a_obs_size = 5

# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()
	create_map(26)

func _physics_process(delta):
	var mouse_offset = (get_viewport().get_mouse_position() - get_viewport().size / 2)
	$Camera2D.position = lerp(Vector2(), mouse_offset.normalized() * 500, mouse_offset.length() / 1000)
	if Input.is_action_just_pressed("ui_accept"):
		var mouse_pos = Map.world_to_map(get_global_mouse_position())
		print(astar.get_point_connections(astar.get_closest_point(Vector3(mouse_pos.x, mouse_pos.y, 0))))
		print(astar.get_closest_point(Vector3(mouse_pos.x, mouse_pos.y, 0)))
		
		if Input.is_action_just_pressed("ui_select"):
			get_tree().reload_current_scene()

func create_map(hyp):
	var height = hyp / 2
	for y in height:
		var length = hyp - (2 * y)
		for x in length:
			Map.set_cell(x + y, y, 15)
			if y != 0:
				Map.set_cell(x + y, -y, 15)
			
			if x >= top_margin and x <= (length - bottom_margin):
				var current_id = astar.get_available_point_id()
				astar.add_point(current_id, Vector3(x + y, y, 0))
				if x > top_margin:
					astar.connect_points(current_id, astar.get_closest_point(Vector3(x + y - 1, y, 0)))
				
				if y != 0:
					astar.connect_points(current_id, astar.get_closest_point(Vector3(x + y, y - 1, 0)))
					current_id = astar.get_available_point_id()
					astar.add_point(current_id, Vector3(x + y, -y, 0))
					astar.connect_points(current_id, astar.get_closest_point(Vector3(x + y, -y + 1, 0)))
					if x > top_margin:
						astar.connect_points(current_id, astar.get_closest_point(Vector3((x + y) - 1, -y, 0)))

	var start_point_offset = (randi() % (height - (top_margin + bottom_margin))) + top_margin
	var end_point_offset = (randi() % (height - (top_margin + bottom_margin))) + top_margin
	var start_point = Vector2(start_point_offset, start_point_offset)
	var end_point = Vector2((hyp - 1) - end_point_offset, -end_point_offset)
	
	Map.set_cellv(start_point, 0)
	Map.set_cellv(end_point, 0)
	
	var start_id = astar.get_closest_point(Vector3(start_point.x, start_point.y, 0))
	var end_id = astar.get_closest_point(Vector3(end_point.x, end_point.y, 0))
	
	for num in range(a_obs_num):
		var current_path = astar.get_point_path(start_id, end_id)
		var section_length = int(round(current_path.size()/a_obs_num))
		var point_in_section = (randi()%(section_length - (section_length/2))) + (section_length/4)
		var obs_point = ((num) * section_length) + point_in_section
		
		if num == 0 and obs_point < 3:
			obs_point = 3
		if num == a_obs_num and obs_point > (current_path.size() - 3):
			obs_point = current_path.size() - 3
			
		var alter_point = current_path[obs_point]
		
		for size in range(a_obs_size):
			for tile in [-size, size]:
				var tile_id = astar.get_closest_point(alter_point + Vector3(tile, tile, 0))
				astar.set_point_weight_scale(tile_id, 500)
				
	path_final = astar.get_point_path(start_id, end_id)
				
	for tile in path_final:
		var current_tile = N|E|S|W
		for dir in road_connects:
			if Map.get_cellv(Vector2(tile.x, tile.y) + dir) != N|E|S|W:
				current_tile -= road_connects[dir]
		Map.set_cellv(Vector2(tile.x, tile.y), current_tile)
		#yield(get_tree(), "idle_frame")
