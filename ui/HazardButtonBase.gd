tool
extends Control

export(String) var hazard_id
export(AtlasTexture) var texture

var mouse_pressed = false
var mouse_over = false

onready var pressed_rect = $Pressed
onready var unpressed_rect = $Unpressed

signal pressed

func _ready():
	if texture:
		$TextureRect.texture = texture


func _gui_input(event):
	if event is InputEventMouseButton:
		if mouse_pressed and event.pressed == false:
			emit_signal("pressed")
			_unpress()
		if event.pressed and event.button_index == BUTTON_LEFT:
			_press()


func _press():
	mouse_pressed = true
	pressed_rect.visible = true
	unpressed_rect.visible = false


func _unpress():
	mouse_pressed = false
	unpressed_rect.visible = true
	pressed_rect.visible = false
