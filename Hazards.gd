extends Node

var current_tool: String
var current_tool_direction: int
var enabled_hazards

enum TileIds {
	POTHOLE = 0,
	SPEED_HUMP = 1,
	CONES = 2
	ONE_WAY = 3,
	STOP_SIGN_RIGHT = 4,
	STOP_SIGN_DOWN = 5,
	STOP_SIGN_LEFT = 6,
	STOP_SIGN_UP = 7,
}

enum Lane {
	LEFT,
	RIGHT
}

##
## Hazard data
##  id: ID of the hazard
##  cost: Amount of money it costs to build
##  weight: Path weight for the AStar calculation
##  residents: How much it affects the resident's feelings
##  install_time: Time it takes to install the hazard
##  perma: How permanent it is (random chance from 0.0 to 1.0 for permanent items)
##  curve_func: Name of function for affecting car's curve animation

const hazard_data = {
	"pothole": {
		"id": "pothole",
		"tile_id": 0,
		"cost": 10.0,
		"weight": 5.0,
		"directional_weight": 1,
		"residents": -15.0,
		"install_time": 1.0,
		"perma": 1.0,
		"curve_func": "pothole_curve",
		"title": "Pothole",
		"description": "Mess up the road with a pothole",
	},
	"cones": {
		"id": "cones",
		"tile_id": 2,
		"weight": 5.0,
		"directional_weight": 1,
		"cost": 20.0,
		"residents": -5.0,
		"install_time": 1.0,
		"perma": 0.4,
		"curve_func": "pothole_curve",
	},
	"one_way": {
		"id": "one_way",
		"tile_id": 3,
		"directional_weight": -1,
		"weight": 100.0,
		"cost": 100.0,
		"residents": 0.0,
		"install_time": 7.0,
		"perma": 1.0,
		"title": "One-Way Street",
		"description": "Make a street one-way",
	},
	"stop_sign": {
		"id": "stop_sign",
		"tile_id": 4,
		"weight": 10.0,
		"directional_weight": 1,
		"cost": 50.0,
		"install_time": 5.0,
		"residents": -5.0,
		"perma": 0.9,
		"title": "Stop Sign",
		"description": "Install a stop sign. Should last a while!",
	},
	"speed_hump": {
		"id": "speed_hump",
		"tile_id": 1,
		"weight": 5.0,
		"cost": 80.0,
		"install_time": 10.0,
		"residents": 2.0,
		"perma": 1.0,
		"title": "Speed Hump",
		"description": "Install a speed hump to slow people down",
	}
}


func get_hazard_by_tile_id(tile_id: int) -> Dictionary:
	match tile_id:
		TileIds.POTHOLE:
			return get_hazard_data("pothole")
		TileIds.CONES:
			return get_hazard_data("cones")
		TileIds.ONE_WAY:
			return get_hazard_data("one_way")
		TileIds.STOP_SIGN_DOWN, TileIds.STOP_SIGN_LEFT, TileIds.STOP_SIGN_UP, TileIds.STOP_SIGN_RIGHT:
			return get_hazard_data("stop_sign")
		TileIds.SPEED_HUMP:
			return get_hazard_data("speed_hump")
	return {}


func get_hazard_data(hazard_id: String) -> Dictionary:
	if hazard_data.has(hazard_id):
		var data = hazard_data[hazard_id]
		if data.has("curve_func") and not data["curve_func"] is FuncRef:
			data["curve_func"] = funcref(self, data["curve_func"])
		
		return data
	
	return {}


func get_hazard_weight(hazard_id: String) -> float:
	if hazard_data.has(hazard_id):
		return hazard_data[hazard_id]["weight"]
	return 1.0



func pothole_curve(base_point: Vector2, curve: Curve2D, _travel_direction: Vector2, _lane: int):
	var offset = Vector2(0, -10)
	## Turn off the offset if the pothole isn't in our lane
	if (_lane == Lane.LEFT and (_travel_direction.x == 1 or _travel_direction.y == 1)) or \
		(_lane == Lane.RIGHT and (_travel_direction.x == -1 or _travel_direction.y == -1)):
		offset = Vector2.ZERO

	if _travel_direction.y != 0:
		offset = offset.rotated(PI / 2)
	
	print("Adding offset! ", offset)
	
	curve.add_point(base_point + offset)


func speed_hump_curve(base_point: Vector2, curve: Curve2D, _travel_direction: Vector2, _lane: int):
	curve.add_point(base_point)


func cones_curve(base_point: Vector2, curve: Curve2D, travel_direction: Vector2, _lane: int):
	curve.add_point(base_point)


func get_direction(direction_lane: int, tile_orientation: int):
	match tile_orientation:
		Road.HORIZONTAL:
			match direction_lane:
				Hazards.Lane.LEFT:
					return Vector2(-1, 0)
				Hazards.Lane.RIGHT:
					return Vector2(1, 0)
		Road.VERTICAL:
			match direction_lane:
				Hazards.Lane.LEFT:
					return Vector2(0, -1)
				Hazards.Lane.RIGHT:
					return Vector2(0, 1)
	return Vector2(1, 0)


func get_tile_info(hazard_data: Dictionary, direction: int, tile_orientation: int):
	var auto_tile = Vector2.ZERO
	var hazard_id = hazard_data["id"]
	var tile_id = hazard_data["tile_id"]
	var is_stop_sign = hazard_id == "stop_sign"
	
	match tile_orientation:
		Road.HORIZONTAL:
			if direction == Hazards.Lane.RIGHT:
				auto_tile = Vector2(0, 0)
			else:
				auto_tile = Vector2(2, 0)
				if is_stop_sign:
					tile_id += 2
		Road.VERTICAL:
			if direction == Hazards.Lane.RIGHT:
				auto_tile = Vector2(1, 0)
				if is_stop_sign:
					tile_id += 1
			else:
				auto_tile = Vector2(3, 0)
				if is_stop_sign:
					tile_id += 3

	if hazard_id == "speed_hump" and auto_tile.x >= 2:
		auto_tile.x -= 2
	
	return {
		"tile_id": tile_id,
		"auto_tile": auto_tile
	}


## Setting current tool
func set_current_tool(new_tool: String, new_tool_direction: int):
	current_tool = new_tool
	current_tool_direction = new_tool_direction
	Events.emit_signal("hazard_tool_changed", new_tool, new_tool_direction)


func set_enabled_hazards(new_enabled_hazards):
	enabled_hazards = new_enabled_hazards
	Events.emit_signal("enabled_hazards", enabled_hazards)

