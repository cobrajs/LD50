extends Control

export(PackedScene) var level

# Game elements
onready var background = $Background
onready var path_shower = $PathShower
onready var animation = $AnimationPlayer
onready var tool_preview = $ToolPreview

onready var car: Sprite = $Path2D/PathFollow2D/Car
onready var path = $Path2D
onready var path_follow = $Path2D/PathFollow2D

var car_moving = false
var car_angle = 0

## Level/Algorithm parts
var road: AStar_Path
var hazards
var enabled_hazards: Array
var level_instance: BaseLevel

var current_path_cost = 0

var resident_base_cost = 0
var resident_current_cost = 0

var current_hazard_tool = ""
var current_hazard_direction = Vector2.ZERO


func _ready():
	Events.connect("show_path", self, "_on_Events_show_path")
	Events.connect("updated_path", self, "_on_Events_update_path")
	Events.connect("path_cost_updated", self, "_on_Events_path_cost_updated")
	Events.connect("send_car", self, "_on_Events_send_car")
	Events.connect("load_level", self, "_on_Events_load_level")
	Events.connect("hazard_tool_changed", self, "_on_Events_hazard_tool_changed")
	Events.connect("deactivate_tools", self, "_on_Events_deactivate_tools")
	
	if level == null:
		level = load("res://levels/Level1.tscn")
	_on_Events_load_level(level)


## Move car along the path
## Update the car's rotation and frame to match the travel direction
func _physics_process(delta):
	if car_moving:
		var previous_position = path_follow.get_global_position()
		path_follow.offset += 200 * delta
		var new_position = path_follow.get_global_position()
		car_angle = rad2deg(new_position.angle_to_point(previous_position))
		if path_follow.unit_offset >= 0.95 and not animation.is_playing():
			animation.play("HideCar")
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


func _gui_input(event):
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == BUTTON_LEFT:
			var cell = road.world_to_map(get_global_mouse_position())
			if current_hazard_tool != "" and cell in road.used_cells and not cell in hazards.get_used_cells():
				road.add_hazard(current_hazard_tool, current_hazard_direction, cell)
	
	if event is InputEventMouseMotion and current_hazard_tool != "":
		tool_preview.clear()
		var cell = tool_preview.world_to_map(get_global_mouse_position())
		if cell in road.used_cells and not cell in hazards.get_used_cells():
			var hazard_data = Hazards.get_hazard_data(current_hazard_tool)
			var tile_info = Hazards.get_tile_info(hazard_data, current_hazard_direction)
			tool_preview.set_cellv(cell, tile_info["tile_id"], false, false, false, tile_info["auto_tile"])


func _on_Events_show_path(path: PoolVector2Array):
	path_shower.clear()
	if path != null:
		for point in path:
			path_shower.set_cellv(point, 0)
		path_shower.update_bitmask_region()


func _on_Events_send_car():
	car_moving = true
	$AnimationPlayer.play("ShowCar")
	path_follow.unit_offset = 0


func get_lane_offset(direction):
	match direction:
		Vector2.LEFT:
			return Vector2(0, -18)
		Vector2.UP:
			return Vector2(8, 0)
		Vector2.RIGHT:
			return Vector2(0, 2)
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
	
	if _path.size() == 0:
		return
	
	## Walk through path and add points to the curve
	for point_index in _path.size() - 1:
		var cell = _path[point_index]
		var next_cell = _path[point_index + 1]
		var direction = next_cell - cell
		lane_offset = get_lane_offset(direction)
		var cell_center = road.map_to_world(cell) + road.cell_size / 2
		var standard_offset = cell_center + lane_offset * rand_range(0.8, 1.2)
		var skip_add_point = false
		
		var hazard_cell = hazards.get_cellv(cell)
		if hazard_cell != -1:
			var hazard_data = Hazards.get_hazard_by_tile_id(hazard_cell)
			if hazard_data.has("curve_func"):
				hazard_data["curve_func"].call_func(standard_offset, path.curve, direction)
				skip_add_point = true
		
		if not skip_add_point:
			if last_direction != null and last_direction != direction:
				var last_lane_offset = get_lane_offset(last_direction)
				var center = cell_center + last_lane_offset + lane_offset
				var offset : Vector2 = last_direction - direction
				path.curve.add_point(center - offset * 2, \
					Vector2(offset.x, 0) * 4, \
					Vector2(0, offset.y) * 4)
			else:
				var offscreen_offset = Vector2.ZERO
				if point_index == 0:
					offscreen_offset = -direction * 32
				path.curve.add_point(standard_offset + offscreen_offset)
			
		last_direction = direction
		
	path.curve.add_point(road.map_to_world(_path[_path.size() - 1]) + Vector2(16, 16) + lane_offset + last_direction * 48)


func _on_Events_load_level(level):
	level_instance = level.instance()
	background.get_parent().add_child_below_node(background, level_instance)
	road = level_instance.get_node("Road")
	hazards = road.get_node("Hazards")
	
	enabled_hazards = level_instance.get_enabled_hazards()
	Events.emit_signal("enabled_hazards", enabled_hazards)
	
	resident_base_cost = get_resident_cost()
	

func get_resident_cost():
	var resident_paths = level_instance.get_resident_paths()
	var resident_cost = 0
	for resident_path in resident_paths:
		resident_cost += road.get_path_cost(resident_path["start"], resident_path["end"])
	
	return resident_cost


func _on_Events_path_cost_updated(path_cost):
	resident_current_cost = get_resident_cost()
	current_path_cost = path_cost


func _on_Events_hazard_tool_changed(new_hazard_tool, new_hazard_direction):
	current_hazard_tool = new_hazard_tool
	current_hazard_direction = new_hazard_direction


func _on_Events_deactivate_tools():
	current_hazard_tool = ""
