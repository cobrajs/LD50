extends TileMap
class_name Road

# The basis of this code is from AndOne's YouTube video "A* Path-Finding for Grid-Based Tilemap in Godot
# https://www.youtube.com/watch?v=dVNH6mIDksQ
# It has been, of course, heavily modified haha

onready var astar = DirectionalWeightAStar2D.new()
onready var used_cells = get_used_cells()

var path: PoolVector2Array
var path_cost: float

var road_start: Vector2
var road_end: Vector2

enum RoadTiles {
	ROAD = 0,
	ROAD_START = 1,
	ROAD_END = 2
}

enum {
	HORIZONTAL,
	VERTICAL,
	OTHER
}


func _ready():
	_add_points()
	_connect_points()

	# Find start and ends of road
	for cell in used_cells:
		var cell_value = get_cellv(cell)
		if cell_value == RoadTiles.ROAD_START:
			road_start = cell
		if cell_value == RoadTiles.ROAD_END:
			road_end = cell
	
	Events.connect("update_path", self, "_on_Events_update_path")
	
	_on_Events_update_path()


func _add_points():
	for cell in used_cells:
		astar.add_point(id(cell), cell, 1.0)


func _connect_points():
	for cell in used_cells:
		for neighbor in [Vector2.UP, Vector2.LEFT, Vector2.DOWN, Vector2.RIGHT]:
			var next_cell = cell + neighbor
			if used_cells.has(next_cell):
				# Change here to implement one-way streets
				astar.connect_points(id(cell), id(next_cell), false)


func get_point_path(start, end):
	return astar.get_point_path(id(start), id(end))


func get_path_cost(start: Vector2, end: Vector2) -> float:
	return astar.get_path_cost(id(start), id(end))


func get_tile_direction(cell: Vector2) -> int:
	var cell_id = get_cellv(cell)
	var autotile = get_cell_autotile_coord(cell.x, cell.y)
	match cell_id:
		0:
			match autotile:
				Vector2(0, 0):
					return HORIZONTAL
				Vector2(1, 0):
					return VERTICAL
		1:
			match autotile:
				Vector2(0, 0), Vector2(1, 0):
					return VERTICAL
				Vector2(0, 1), Vector2(1, 1):
					return HORIZONTAL
		2:
			match autotile:
				Vector2(0, 0), Vector2(1, 0):
					return VERTICAL
				Vector2(0, 1), Vector2(1, 1):
					return HORIZONTAL
				
	return OTHER
	

func update_path():
	path = get_point_path(road_start, road_end)
	path_cost = get_path_cost(road_start, road_end)
	print("Updated path: ", path_cost)
	Events.emit_signal("updated_path_cost", path_cost)
	Events.emit_signal("updated_path", path)


func _on_Events_update_path():
	if road_start and road_end:
		update_path()
		if Events.debug:
			Events.emit_signal("show_path", path)


# Cantor pairing function
func id(point : Vector2):
	var a = point.x
	var b = point.y
	return (a + b) * (a + b + 1) / 2 + b
