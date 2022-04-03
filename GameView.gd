extends Control


# Right Bar UI
onready var path_weight_label = $RightBar/MarginContainer/VBoxContainer/PathWeight/Output
onready var traffic_bar = $RightBar/MarginContainer/VBoxContainer/Traffic/ProgressBar

onready var tool_menu = $ToolMenu

func _ready():
	Events.connect("path_weight_updated", self, "_on_Events_path_weight_updated")
	
	traffic_bar.rect_size.y = 32


func _notification(what):
	if what == MainLoop.NOTIFICATION_WM_QUIT_REQUEST:
		get_tree().quit()

func _unhandled_input(event):
	if event.is_action_pressed("ui_quit"):
		get_tree().notification(MainLoop.NOTIFICATION_WM_QUIT_REQUEST)


func _on_Events_path_weight_updated(weight: float):
	path_weight_label.text = str(weight)


func _process(delta):
	traffic_bar.value += traffic_bar.step * delta
	
	if traffic_bar.value >= traffic_bar.max_value:
		traffic_bar.value = traffic_bar.min_value


func _on_ToolButton_pressed():
	Events.emit_signal("update_path")


func _on_GoCar_pressed():
	Events.emit_signal("send_car")


func _on_Tools_pressed():
	print("TOOOOOLS!")
