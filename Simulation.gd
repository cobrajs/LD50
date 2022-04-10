extends Node

var hazards = {}
var hazards_display: TileMap

var road: Road
var path: Path2D

onready var Car = preload("res://simulation/Car.tscn")
var cars
var add_car_cooldown = 0

## Simulation state
var playing: bool = false
## Traffic level range is 0 to 1
var traffic_level: float = 0.0
var traffic_base_cost: int = 0
## Worth It level range is -1 to 1
var worth_it_level: float = 0.0
## Resident Feelings level range is -1 to 1
var resident_feelings_level: float = 0.0
var resident_hazard_cost: float = 0.0
var budget_amount: int = 100
var budget_max: int = 100

## Residents
var resident_paths: Array
var resident_base_cost: int
var resident_cost: int


func _ready():
	Events.connect("send_car", self, "_on_Events_send_car")
	Events.connect("updated_path", self, "_on_Events_updated_path")

	if road:
		road.update_path()

func reset():
	traffic_level = 0.0

	send_state_updates()	

## Send out any Events for the simulation state
func send_state_updates():
	Events.emit_signal("traffic_updated", traffic_level * 100)
	Events.emit_signal("worth_it_updated", worth_it_level * 50)
	Events.emit_signal("resident_feelings_updated", resident_feelings_level * 50)


##
## Simulation controls
func start():
	playing = true
	Events.emit_signal("enable_tools")
	reset()

func step(delta):
	if not playing:
		return
	
	var car_count = path.get_child_count()
	
	if car_count > 0:
		for car in path.get_children():
			car.move_along(delta)

	if add_car_cooldown <= 0 and car_count < (worth_it_level + 0.5) * 4:
		var car = Car.instance()
		path.add_child(car)
		add_car_cooldown = (worth_it_level + 0.5) * 4
		print("Car should: ", (worth_it_level + 0.5) * 4)
	
	if add_car_cooldown > 0:
		add_car_cooldown -= 1 * delta
		print("Add Car: ", add_car_cooldown)
	
	traffic_level += 0.02 * delta
	worth_it_level = ((traffic_base_cost + (traffic_base_cost * traffic_level)) - road.path_cost) / traffic_base_cost
	resident_feelings_level = (resident_base_cost - resident_cost + resident_hazard_cost) / resident_base_cost
	
	send_state_updates()	

		
func pause():
	playing = not playing

func stop():
	playing = false


## Dealing with Hazards
#Simulation.add_hazard(Hazards.current_tool, Hazards.current_tool_direction, cell, tile_orientation)
func add_hazard(hazard_id: String, direction_lane: int, cell: Vector2, tile_orientation: int):
	var hazard_data = Hazards.get_hazard_data(hazard_id)
	if cell in road.used_cells:
		var weight = hazard_data["weight"] if hazard_data.has("weight") else 1.0
		
		var hazard_direction = Hazards.get_direction(direction_lane, tile_orientation)

		if hazard_data.has("directional_weight"):
			road.astar.add_directional_weight(road.id(cell), road.id(cell + hazard_direction * hazard_data["directional_weight"]), weight)
		else:
			road.astar.set_point_weight_scale(road.id(cell), weight)
		
		## For one-way hazards, only connect the tiles in one direction
		if hazard_id == "one_way" and false:
			var start_cell = cell
			var next_cell = cell + hazard_direction
			road.astar.disconnect_points(road.id(start_cell), road.id(next_cell))
			road.astar.connect_points(road.id(start_cell), road.id(next_cell), false)

		var tile_info = Hazards.get_tile_info(hazard_data, direction_lane, tile_orientation)
		hazards_display.set_cell(cell.x, cell.y, tile_info["tile_id"], false, false, false, tile_info["auto_tile"])
		hazards[cell] = {
			"id": hazard_id,
			"lane": direction_lane
		}
		
		road.update_path()

		budget_amount -= hazard_data["cost"]
		resident_hazard_cost += hazard_data["residents"]
		Events.emit_signal("budget_updated", budget_amount)
		print("Budget: ", budget_amount, " Resident amount: ", resident_hazard_cost)


## Reset hazard variables. Should only be done after loading a new road because
##  the weights are added directly to the AStar graph in Road
func reset_hazards():
	hazards_display.clear()
	hazards.clear()


## Dealing with the road
func load_road(new_road: Road):
	road = new_road
	reset_hazards()
	road.update_path()
	traffic_base_cost = road.path_cost

func get_path_cost():
	return road.path_cost

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
func update_path():
	## Clear out the old curve or create one if it hasn't been created
	if !path.curve:
		path.curve = Curve2D.new()
	path.curve.clear_points()
	
	var last_direction = null
	var lane_offset
	var road_path_size = road.path.size()
	print("loading path: ", road_path_size, " cost: ", road.path_cost)
	if not road.path or road_path_size == 0:
		return
	
	## Walk through path and add points to the curve
	for point_index in road_path_size - 1:
		var cell = road.path[point_index]
		var next_cell = road.path[point_index + 1]
		var direction = next_cell - cell
		lane_offset = get_lane_offset(direction)
		var cell_center = road.map_to_world(cell) + road.cell_size / 2
		var standard_offset = cell_center + lane_offset * rand_range(0.8, 1.2)
		var skip_add_point = false
		
		if hazards.has(cell):
			var hazard_cell = hazards.get(cell)
			var hazard_data = Hazards.get_hazard_data(hazard_cell["id"])
			if hazard_data.has("curve_func"):
				hazard_data["curve_func"].call_func(standard_offset, path.curve, direction, hazard_cell["lane"])
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
		
	path.curve.add_point(road.map_to_world(road.path[road_path_size - 1]) + Vector2(16, 16) + lane_offset + last_direction * 48)


## Dealing with Residents
func load_resident_paths(new_resident_paths):
	resident_paths = new_resident_paths
	
	resident_base_cost = get_resident_cost()
	resident_cost = resident_base_cost
	
	emit_resident_feelings()

func get_resident_cost():
	var total_cost = 0
	
	for resident_path in resident_paths:
		total_cost += road.get_path_cost(resident_path["start"], resident_path["end"])
	
	return total_cost

func emit_resident_feelings():
	Events.emit_signal("resident_feelings_updated", resident_base_cost - resident_cost)

## Events
func _on_Events_send_car():
	if not path:
		return
	
	var car = Car.instance()
	path.add_child(car)

func _on_Events_updated_path(_path):
	print("Path updates!")
	if not road:
		return
	update_path()
	resident_cost = get_resident_cost()
