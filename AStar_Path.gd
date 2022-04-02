extends TileMap
class_name AStar_Path

# Most of this code is from AndOne's YouTube video "A* Path-Finding for Grid-Based Tilemap in Godot
# https://www.youtube.com/watch?v=dVNH6mIDksQ

onready var astar = DirectionalWeightAStar2D.new()
onready var used_cells = get_used_cells()

var path : PoolVector2Array


func _ready():
	_add_points()
	_connect_points()


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


func _get_path(start, end):
	path = astar.get_point_path(id(start), id(end))


# Cantor pairing function
func id(point : Vector2):
	var a = point.x
	var b = point.y
	return (a + b) * (a + b + 1) / 2 + b

