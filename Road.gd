extends AStar_Path

# The basis of this code is from AndOne's YouTube video "A* Path-Finding for Grid-Based Tilemap in Godot
# https://www.youtube.com/watch?v=dVNH6mIDksQ
# It has been, of course, heavily modified haha

onready var car = $Car
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
		var weight = 1.0
		match hazard_type:
			0: # Pothole
				weight = 5.0
			1: # Speed hump
				weight = 5.0
			2: # Cones
				weight = 5.0
			4: # Stop sign right
				astar.add_directional_weight(id(hazard), id(hazard + Vector2.RIGHT), 10.0)
			5: # Stop sign down
				astar.add_directional_weight(id(hazard), id(hazard + Vector2.DOWN), 10.0)
			6: # Stop sign left
				astar.add_directional_weight(id(hazard), id(hazard + Vector2.LEFT), 10.0)
			7: # Stop sign up
				astar.add_directional_weight(id(hazard), id(hazard + Vector2.UP), 10.0)
				
		astar.set_point_weight_scale(id(hazard), weight)
		
		# For one-way hazards, only connect the tiles in one direction
		if hazard_type == 3:
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
	Events.emit_signal("path_weight_updated", get_path_weight(from, to))


func get_path_weight(from, to):
	return astar.get_path_cost(id(from), id(to))


func _input(event):
	if (event is InputEventMouseButton and event.is_pressed() and event.button_index == BUTTON_LEFT) and not car_moving:
		print(event, get_viewport().get_mouse_position(), get_global_mouse_position(), world_to_map(get_global_mouse_position()))
		var mouse_position = world_to_map(get_global_mouse_position())
		if used_cells.has(mouse_position):
			var car_position = world_to_map(car.global_position)
			_get_path(car_position, mouse_position)
			car_moving = true
			Events.emit_signal("show_path", null)
			move()
	
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == BUTTON_RIGHT:
		var mouse_position = world_to_map(get_global_mouse_position())
		var hazard = hazards.get_cellv(mouse_position)
		if hazard > -1:
			print("Hazard here! ", hazard, mouse_position, "  ", hazards.get_cell_autotile_coord(mouse_position.x, mouse_position.y))
		
		if used_cells.has(mouse_position):
			var car_position = world_to_map(car.global_position)
			_get_path(car_position, mouse_position)
			Events.emit_signal("show_path", path)


func move():
	for point in path:
		var next_position = map_to_world(point)
		var car_direction = (next_position - car.global_position).normalized()
		match car_direction:
			Vector2.UP:
				car.frame = 0
			Vector2.DOWN:
				car.frame = 3
			Vector2.LEFT:
				car.frame = 2
			Vector2.RIGHT:
				car.frame = 1
		car.global_position = next_position + tile_center + car_offset.rotated(car_direction.angle())
		yield(get_tree().create_timer(0.1), "timeout")
	
	car_moving = false


func _on_Events_update_path():
	if road_start and road_end:
		_get_path(road_start, road_end)
		Events.emit_signal("show_path", path)
