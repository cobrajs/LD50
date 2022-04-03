extends Control

onready var title = $MainMenu/Label

var time

func _ready():
	time = 0


func _process(delta):
	title.rect_position.x = sin(time) * 30 + 15
	title.rect_position.y = sin(time * 4) * 8 + 4
	time += delta * 1
	if time > PI * 2:
		time = 0


func _input(event):
	if event.is_action_pressed("ui_quit"):
		_on_Quit_pressed()
	

func _on_Quit_pressed():
	get_tree().notification(MainLoop.NOTIFICATION_WM_QUIT_REQUEST)
