extends Control


# Right Bar UI
onready var path_cost_label = $RightBar/MarginContainer/VBoxContainer/PathCost/Output
onready var traffic_bar = $RightBar/MarginContainer/VBoxContainer/Traffic/CustomProgress
onready var worth_it_bar = $RightBar/MarginContainer/VBoxContainer/WorhtIt/CustomProgress
onready var residents_bar = $RightBar/MarginContainer/VBoxContainer/Residents/CustomProgress
onready var budget_bar = $RightBar/MarginContainer/VBoxContainer/Budget/CustomProgress

onready var tool_menu = $ToolMenu
onready var tools_holder = $ToolMenu/ToolsHolder

func _ready():
	Events.connect("updated_path_cost", self, "_on_Events_updated_path_cost")
	
	for hazard_tool in tools_holder.get_children():
		hazard_tool.connect("pressed", self, "_on_hazard_tool_pressed")
	
	Events.connect("enabled_hazards", self, "_on_Events_enabled_hazards")
	if Hazards.enabled_hazards:
		_on_Events_enabled_hazards(Hazards.enabled_hazards)
	
	Events.connect("budget_updated", self, "_on_Events_budget_updated")
	Events.connect("budget_updated", self, "_on_Events_budget_updated")
	Events.connect("budget_updated", self, "_on_Events_budget_updated")

	Events.connect("deactivate_tools", self, "_on_Events_deactivate_tools")



func _notification(what):
	if what == MainLoop.NOTIFICATION_WM_QUIT_REQUEST:
		get_tree().quit()

func _unhandled_input(event):
	if event.is_action_pressed("ui_quit"):
		get_tree().notification(MainLoop.NOTIFICATION_WM_QUIT_REQUEST)


func _on_Events_updated_path_cost(cost: float):
	path_cost_label.text = str(cost)


func _process(delta):
	traffic_bar.value += traffic_bar.step * delta * 10
		
	if traffic_bar.value >= traffic_bar.max_value:
		traffic_bar.value = traffic_bar.min_value
	
	worth_it_bar.value = traffic_bar.value - traffic_bar.max_value / 2
	residents_bar.value = traffic_bar.value - traffic_bar.max_value / 2
	budget_bar.value = traffic_bar.value


func _on_ToolButton_pressed():
	Events.emit_signal("update_path")


func _on_GoCar_pressed():
	Events.emit_signal("send_car")


func _on_Tools_pressed():
	print("TOOOOOLS!")


func _on_hazard_tool_pressed(hazard_id: String, hazard_lane: int):
	print("Pressed: ", hazard_id)
	Hazards.set_current_tool(hazard_id, hazard_lane)


func _on_Events_deactivate_tools():
	Hazards.set_current_tool("", 0)
	

func _on_Events_enabled_hazards(enabled_hazards):
	var visible_count = 0
	for hazard_tool in tools_holder.get_children():
		var is_visible = hazard_tool.hazard_id in enabled_hazards
		hazard_tool.visible = is_visible
		hazard_tool.pitch_change = 1.0 + visible_count * (1.0 / 7.0)
		visible_count += 1 if is_visible else 0


func _on_Play_pressed():
	Simulation.start()
