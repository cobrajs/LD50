extends AStar2D
class_name DirectionalWeightAStar2D

var _directional_weights = {}


func add_directional_weight(from: int, to: int, weight_scale: float):
	_directional_weights[_directional_weight_key(from, to)] = weight_scale


func _compute_cost(from_id, to_id):
	var from_weight = get_point_weight_scale(from_id)
	var to_weight = get_point_weight_scale(to_id)
	var key = _directional_weight_key(from_id, to_id)
	if _directional_weights.has(key):
		return from_weight + to_weight + _directional_weights[key]
	
	return from_weight + to_weight


func _estimate_cost(from_id, to_id):
	return _compute_cost(from_id, to_id)


func _directional_weight_key(from: int, to: int):
	return str(from) + ":" + str(to)


func get_path_cost(from_id: int, to_id: int):
	var path = get_id_path(from_id, to_id)
	var total_cost = 0
	for point_index in path.size() - 1:
		total_cost += _compute_cost(path[point_index], path[point_index + 1])
	return total_cost
