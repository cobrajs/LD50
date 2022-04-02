extends AStar_Path

# Most of this code is from AndOne's YouTube video "A* Path-Finding for Grid-Based Tilemap in Godot
# https://www.youtube.com/watch?v=dVNH6mIDksQ

onready var car = $Car
onready var hazards = $Hazards


var car_moving = false
var car_offset = Vector2(8, 0)
var tile_center = Vector2(8, 8)


func _get_point_weight(cell):
	return 1


func _input(event):
	if (event is InputEventMouseButton and event.is_pressed() and event.button_index == BUTTON_LEFT) and not car_moving:
		var mouse_position = world_to_map(get_global_mouse_position())
		if used_cells.has(mouse_position):
			var car_position = world_to_map(car.global_position)
			_get_path(car_position, mouse_position)
			car_moving = true
			move()
	
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == BUTTON_RIGHT:
		pass


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
