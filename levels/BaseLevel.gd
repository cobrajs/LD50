extends Node2D
class_name BaseLevel

export(String) var level_title = "Level"
export(int) var level_number = 1
export(String, MULTILINE) var level_text = ""
export(int) var level_start_budget = 100

export(String, MULTILINE) var enabled_hazards = "potholes,cones,speed_hump"


func get_enabled_hazards():
	return enabled_hazards.split(",")
