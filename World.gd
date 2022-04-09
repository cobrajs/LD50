extends Control

export(PackedScene) var level

# Game elements
onready var background = $Background
onready var path_shower = $PathShower
onready var animation = $AnimationPlayer
onready var tool_preview = $ToolPreview

onready var path = $SimulationPath
onready var hazards: TileMap = $Hazards

## Level/Algorithm parts
var level_instance: BaseLevel


func _ready():
	Events.connect("show_path", self, "_on_Events_show_path")
	Events.connect("load_level", self, "_on_Events_load_level")
	Events.connect("hazard_tool_changed", self, "_on_Events_hazard_tool_changed")
	
	Simulation.path = path
	Simulation.hazards_display = hazards
		
	if level == null:
		level = load("res://levels/Level1.tscn")
	_on_Events_load_level(level)


func _gui_input(event):
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == BUTTON_LEFT:
			var cell = Simulation.road.world_to_map(get_global_mouse_position())
			if Hazards.current_tool != "" and cell in Simulation.road.used_cells and not cell in hazards.get_used_cells():
				var tile_orientation = Simulation.road.get_tile_direction(cell)
				if tile_orientation != Road.OTHER:
					Simulation.add_hazard(Hazards.current_tool, Hazards.current_tool_direction, cell, tile_orientation)
					Events.emit_signal("deactivate_tools")
		
	if event is InputEventMouseMotion and Hazards.current_tool != "":
		tool_preview.clear()
		var cell = tool_preview.world_to_map(get_global_mouse_position())
		if cell in Simulation.road.used_cells and not cell in hazards.get_used_cells():
			var tile_orientation = Simulation.road.get_tile_direction(cell)
			if tile_orientation != Road.OTHER:
				var hazard_data = Hazards.get_hazard_data(Hazards.current_tool)
				var tile_info = Hazards.get_tile_info(hazard_data, Hazards.current_tool_direction, tile_orientation)
				tool_preview.set_cell(cell.x, cell.y, tile_info["tile_id"], false, false, false, tile_info["auto_tile"])


func _process(delta):
	Simulation.step(delta)


func _on_Events_show_path(path_to_show: PoolVector2Array):
	path_shower.clear()
	if path != null:
		for point in path_to_show:
			path_shower.set_cellv(point, 0)
		path_shower.update_bitmask_region()


func _on_Events_load_level(level_to_load):
	level_instance = level_to_load.instance()
	hazards.get_parent().add_child_below_node(hazards, level_instance)
	Simulation.load_road(level_instance.get_node("Road"))
	Simulation.load_resident_paths(level_instance.get_resident_paths())

	Hazards.set_enabled_hazards(level_instance.get_enabled_hazards())
	

func _on_World_mouse_exited():
	tool_preview.clear()
