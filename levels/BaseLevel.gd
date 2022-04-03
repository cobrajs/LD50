extends Node2D
class_name BaseLevel

export(String) var level_title = "Level"
export(int) var level_number = 1
export(String, MULTILINE) var level_text = ""
export(int) var level_start_budget = 100

export(String, MULTILINE) var enabled_hazards = "potholes,cones,speed_hump"

export(PoolVector2Array) var resident_start_ends


func get_enabled_hazards():
	return enabled_hazards.split(",")


func get_resident_paths():
	var paths = []
	
	if resident_start_ends and resident_start_ends.size() > 1:
		for index in range(0, resident_start_ends.size(), 2):
			paths.append({
				"start": resident_start_ends[index],
				"end": resident_start_ends[index + 1]
			})
	
	return paths
