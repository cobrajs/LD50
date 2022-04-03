extends Node

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



func pothole_curve(base_point: Vector2, curve: Curve2D, travel_direction: Vector2):
	print("Pothole look out for the pothole")
	curve.add_point(base_point)


func get_tile_info(hazard_data: Dictionary, direction: Vector2):
	var auto_tile = Vector2.ZERO
	var hazard_id = hazard_data["id"]
	var tile_id = hazard_data["tile_id"]
	
	match direction:
		Vector2.RIGHT:
			auto_tile = Vector2(0, 0)
		Vector2.UP:
			auto_tile = Vector2(3, 0)
			if hazard_id == "stop_sign":
				tile_id += 1
		Vector2.DOWN:
			auto_tile = Vector2(1, 0)
			if hazard_id == "stop_sign":
				tile_id += 2
		Vector2.LEFT:
			auto_tile = Vector2(2, 0)
			if hazard_id == "stop_sign":
				tile_id += 3
	
	if hazard_id == "speed_hump" and auto_tile.x >= 2:
		auto_tile.x -= 2
	
	return {
		"tile_id": tile_id,
		"auto_tile": auto_tile
	}

