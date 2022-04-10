extends Node

signal show_path(path)
signal updated_path(path)
signal updated_path_cost(cost)

signal update_path

signal send_car
signal start_level
signal restart_level

signal load_level(level)
signal enabled_hazards(hazard_ids)

## Signals for display on the game view
signal traffic_updated(traffic_value)
signal traffic_range_updated(min_value, max_value)

signal worth_it_updated(worth_it_value)
signal worth_it_range_updated(min_value, max_value)

signal resident_feelings_updated(resident_feelings_value)
signal resident_feelings_range_updated(min_value, max_value)

signal budget_updated(budget_value)
signal budget_range_updated(min_value, max_value)

## Signals for hazard changes
signal hazard_tool_changed(new_tool, new_tool_direction)
signal hazard_placed
signal deactivate_tools
signal enable_tools
signal disable_tools

var debug = false
