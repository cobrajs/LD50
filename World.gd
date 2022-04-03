extends Control

# Game elements
onready var path_shower = $PathShower
onready var road = $Level1/Road

onready var car = $Path2D/PathFollow2D/Car
onready var path = $Path2D
onready var path_follow = $Path2D/PathFollow2D

var car_moving = false

func _ready():
	Events.connect("show_path", self, "_on_Events_show_path")
	Events.connect("updated_path", self, "_on_Events_update_path")
	Events.connect("send_car", self, "_on_Events_send_car")


func _physics_process(delta):
	if car_moving:
		path_follow.offset += 200 * delta
		if path_follow.unit_offset >= 0.99:
			car_moving = false


func _on_Events_show_path(path: PoolVector2Array):
	path_shower.clear()
	if path != null:
		for point in path:
			path_shower.set_cellv(point, 0)
		path_shower.update_bitmask_region()


func _on_Events_send_car():
	car_moving = true
	path_follow.unit_offset = 0


func _on_Events_update_path(_path):
	if !path.curve:
		path.curve = Curve2D.new()
	path.curve.clear_points()
	var last_direction = null
	for point_index in _path.size() - 1:
		var cell = _path[point_index]
		var next_cell = _path[point_index + 1]
		var direction = next_cell - cell
		match direction:
			Vector2.LEFT:
				print("Left")
			Vector2.UP:
				print("Up")
			Vector2.RIGHT:
				print("Right")
			Vector2.DOWN:
				print("Down")
		if last_direction != null and last_direction != direction and false:
			print("Direction change! ", last_direction, " ", direction)
			var center = road.map_to_world(cell) + Vector2(16, 16)
			var offset = last_direction + direction
			path.curve.add_point(center + offset * 16, \
				road.map_to_world(_path[point_index - 1]) + Vector2(16, 16), \
				road.map_to_world(next_cell) + Vector2(16, 16))
		else:
			path.curve.add_point(road.map_to_world(cell) + Vector2(16, 16))
			
		last_direction = direction
		
		#print(cell, ", ", road.map_to_world(cell))
	path.curve.add_point(road.map_to_world(_path[_path.size() - 1]) + Vector2(16, 16))

