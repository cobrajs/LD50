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
		"cost": 50.0,
		"weight": 5.0,
		"residents": -10.0,
		"install_time": 1.0,
		"perma": 1.0,
		"curve_func": "pothole_curve2",
	},
	"cones": {
		"id": "cones",
		"weight": 1.0,
	},
	"one_way": {
		"id": "one_way",
		"weight": 1.0,
	},
	"stop_sign": {
		"id": "stop_sign",
		"weight": 1.0,
	},
	"speed_hump": {
		"id": "speed_hump",
		"weight": 1.0,
	}
}


func get_hazard_by_tile_id(tile_id: int) -> Dictionary:
	match tile_id:
		TileIds.POTHOLE:
			return hazard_data["pothole"]
		TileIds.CONES:
			return hazard_data["cones"]
		TileIds.ONE_WAY:
			return hazard_data["one_way"]
		TileIds.STOP_SIGN_DOWN, TileIds.STOP_SIGN_LEFT, TileIds.STOP_SIGN_UP, TileIds.STOP_SIGN_RIGHT:
			return hazard_data["stop_sign"]
		TileIds.SPEED_HUMP:
			return hazard_data["speed_hump"]
	return {}


func get_hazard_data(hazard_id: String) -> Dictionary:
	if hazard_data.has(hazard_id):
		var data = hazard_data[hazard_id]
		if data.has("curve_func"):
			data["curve_func"] = funcref(self, data["curve_func"])
		
		return data
	
	return {}


func get_hazard_weight(hazard_id: String) -> float:
	if hazard_data.has(hazard_id):
		return hazard_data[hazard_id]["weight"]
	return 1.0



func pothole_curve(base_point: Vector2, curve: Curve2D, travel_direction: Vector2):
	curve.add_point(base_point)


func pothole_curve2():
	print("you canlled?")
