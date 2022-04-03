extends Control

# Game elements
onready var path_shower = $PathShower
onready var road = $Level1/Road

onready var car: Sprite = $Path2D/PathFollow2D/Car
onready var path = $Path2D
onready var path_follow = $Path2D/PathFollow2D

var car_moving = false
var car_angle = 0

func _ready():
	Events.connect("show_path", self, "_on_Events_show_path")
	Events.connect("updated_path", self, "_on_Events_update_path")
	Events.connect("send_car", self, "_on_Events_send_car")


## Move car along the path
## Update the car's rotation and frame to match the travel direction
func _physics_process(delta):
	if car_moving:
		var previous_position = path_follow.get_global_position()
		path_follow.offset += 200 * delta
		var new_position = path_follow.get_global_position()
		car_angle = rad2deg(new_position.angle_to_point(previous_position))
		if path_follow.unit_offset >= 0.99:
			car_moving = false
		if car_angle <= 45 and car_angle >= -45: # Right
			car.frame = 1
		elif car_angle > 45 and car_angle < 135: # Down
			car.frame = 3
			car_angle -= 90
		elif (car_angle >= 135 and car_angle <= 180) or (car_angle <= -135 and car_angle >= -180): # Left
			car.frame = 2
			if car_angle > 0:
				car_angle -= 180
			else:
				car_angle += 180
		elif car_angle < -45 and car_angle > -135:
			car.frame = 0
			car_angle += 90

		car.rotation = deg2rad(car_angle)


func _on_Events_show_path(path: PoolVector2Array):
	path_shower.clear()
	if path != null:
		for point in path:
			path_shower.set_cellv(point, 0)
		path_shower.update_bitmask_region()


func _on_Events_send_car():
	car_moving = true
	path_follow.unit_offset = 0


func get_lane_offset(direction):
	match direction:
		Vector2.LEFT:
			return Vector2(0, -10)
		Vector2.UP:
			return Vector2(8, 0)
		Vector2.RIGHT:
			return Vector2(0, 8)
		Vector2.DOWN:
			return Vector2(-8, 0)
	return Vector2.ZERO
	

## When the path is updated, generate a new curve for the car to follow
## Works to make sure the car follows in its lane and adds a bit of noise to
##  the path as well. Curving around corners is wonky
func _on_Events_update_path(_path):
	## Clear out the old curve or create one if it hasn't been created
	if !path.curve:
		path.curve = Curve2D.new()
	path.curve.clear_points()
	
	var last_direction = null
	var lane_offset
	for point_index in _path.size() - 1:
		var cell = _path[point_index]
		var next_cell = _path[point_index + 1]
		var direction = next_cell - cell
		lane_offset = get_lane_offset(direction)
		if last_direction != null and last_direction != direction:
			var last_lane_offset = get_lane_offset(last_direction)
			var center = road.map_to_world(cell) + Vector2(16, 16) + last_lane_offset + lane_offset
			var offset : Vector2 = last_direction - direction
			path.curve.add_point(center - offset * 2, \
				Vector2(offset.x, 0) * 4, \
				Vector2(0, offset.y) * 4)
		else:
			var offscreen_offset = Vector2.ZERO
			if point_index == 0:
				offscreen_offset = -direction * 32
			path.curve.add_point(road.map_to_world(cell) + Vector2(16, 16) + lane_offset * rand_range(0.8, 1.2) + offscreen_offset)
			
		last_direction = direction
		
	path.curve.add_point(road.map_to_world(_path[_path.size() - 1]) + Vector2(16, 16) + lane_offset + last_direction * 48)

