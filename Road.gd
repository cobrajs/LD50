extends AStar_Path
class_name Road

# The basis of this code is from AndOne's YouTube video "A* Path-Finding for Grid-Based Tilemap in Godot
# https://www.youtube.com/watch?v=dVNH6mIDksQ
# It has been, of course, heavily modified haha

onready var hazards = $Hazards

var car_moving = false
var car_offset = Vector2(8, 0)
var tile_center = Vector2(8, 8)

var road_start: Vector2
var road_end: Vector2

enum RoadTiles {
	ROAD = 0,
	ROAD_START = 1,
	ROAD_END = 2
}


func _ready():
	var all_hazards = hazards.get_used_cells()
	for hazard in all_hazards:
		var hazard_type = hazards.get_cellv(hazard)
		var hazard_data = Hazards.get_hazard_by_tile_id(hazard_type)
		var weight = hazard_data["weight"] if hazard_data.has("weight") else 1.0

		match hazard_type:
			Hazards.TileIds.STOP_SIGN_RIGHT:
				astar.add_directional_weight(id(hazard), id(hazard + Vector2.RIGHT), 10.0)
			Hazards.TileIds.STOP_SIGN_DOWN: # Stop sign down
				astar.add_directional_weight(id(hazard), id(hazard + Vector2.DOWN), 10.0)
			Hazards.TileIds.STOP_SIGN_LEFT: # Stop sign left
				astar.add_directional_weight(id(hazard), id(hazard + Vector2.LEFT), 10.0)
			Hazards.TileIds.STOP_SIGN_UP: # Stop sign up
				astar.add_directional_weight(id(hazard), id(hazard + Vector2.UP), 10.0)
				
		astar.set_point_weight_scale(id(hazard), weight)
		
		# For one-way hazards, only connect the tiles in one direction
		if hazard_type == Hazards.TileIds.ONE_WAY:
			var direction = Vector2.ZERO
			var one_way_auto = hazards.get_cell_autotile_coord(hazard.x, hazard.y)
			match int(one_way_auto.x):
				0: direction = Vector2.RIGHT
				1: direction = Vector2.DOWN
				2: direction = Vector2.LEFT
				3: direction = Vector2.UP
			var start_cell = hazard
			var next_cell = hazard + direction
			astar.disconnect_points(id(start_cell), id(next_cell))
			astar.connect_points(id(start_cell), id(next_cell), false)
	
	Events.connect("update_path", self, "_on_Events_update_path")
	
	# Find start and ends of road
	for cell in used_cells:
		var cell_value = get_cellv(cell)
		if cell_value == RoadTiles.ROAD_START:
			road_start = cell
		if cell_value == RoadTiles.ROAD_END:
			road_end = cell

func _get_path(from, to):
	._get_path(from, to)
	Events.emit_signal("path_cost_updated", get_path_cost(from, to))
	Events.emit_signal("updated_path", path)


func get_path_cost(from, to):
	return astar.get_path_cost(id(from), id(to))


func add_hazard(hazard_id: String, direction: Vector2, cell: Vector2):
	var hazard_data = Hazards.get_hazard_data(hazard_id)
	if cell in used_cells:
		var weight = hazard_data["weight"] if hazard_data.has("weight") else 1.0

		if hazard_id == "stop_sign":
			astar.add_directional_weight(id(cell), id(cell + direction), 10.0)
				
		astar.set_point_weight_scale(id(cell), weight)
		
		# For one-way hazards, only connect the tiles in one direction
		if hazard_id == "one_way":
			var start_cell = cell
			var next_cell = cell + direction
			astar.disconnect_points(id(start_cell), id(next_cell))
			astar.connect_points(id(start_cell), id(next_cell), false)
		
		match direction:
			Vector2.RIGHT:
				pass
	
		Events.connect("update_path", self, "_on_Events_update_path")


func _on_Events_update_path():
	if road_start and road_end:
		_get_path(road_start, road_end)
		if Events.debug:
			Events.emit_signal("show_path", path)
