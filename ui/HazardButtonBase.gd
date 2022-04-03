tool
extends Control

export(String) var hazard_id
export(AtlasTexture) var texture
export(float) var pitch_change = 1.0 setget update_pitch_change
export(bool) var active_tool = false
export(Vector2) var direction = Vector2.ZERO

var mouse_pressed = false
var mouse_over = false
var use_pressed_rect
var use_unpressed_rect

onready var pressed_rect = $Pressed
onready var unpressed_rect = $Unpressed
onready var pressed_active_rect = $PressedActive
onready var unpressed_active_rect = $UnpressedActive
onready var texture_rect = $TextureRect

signal pressed

func _ready():
	if texture:
		$TextureRect.texture = texture
	
	update_pitch_change(pitch_change)
	Events.connect("hazard_tool_changed", self, "_on_Events_hazard_tool_changed")
	Events.connect("deactivate_tools", self, "_on_Events_deactivate_tools")
	
	if active_tool:
		use_pressed_rect = pressed_active_rect
		use_unpressed_rect = unpressed_active_rect
	else:
		use_pressed_rect = pressed_rect
		use_unpressed_rect = unpressed_rect


func _gui_input(event):
	if event is InputEventMouseButton:
		if mouse_pressed and event.pressed == false:
			emit_signal("pressed", hazard_id, direction)
			_unpress()
		if event.pressed and event.button_index == BUTTON_LEFT:
			_press()


func _press():
	mouse_pressed = true
	use_pressed_rect.visible = true
	use_unpressed_rect.visible = false
	$ClickDown.play()
	
	if active_tool and direction != Vector2.ZERO:
		direction = direction.rotated(PI / 2).round()
		texture_rect.rect_pivot_offset = texture_rect.rect_size / 2
		texture_rect.rect_rotation = rad2deg(direction.angle())


func _unpress():
	mouse_pressed = false
	use_unpressed_rect.visible = true
	use_pressed_rect.visible = false
	$ClickUp.play()


func set_active():
	active_tool = true
	use_pressed_rect = pressed_active_rect
	use_unpressed_rect = unpressed_active_rect
	pressed_rect.visible = false
	unpressed_rect.visible = false
	unpressed_active_rect.visible = true
	pressed_active_rect.visible = false


func set_inactive():
	active_tool = false
	use_pressed_rect = pressed_rect
	use_unpressed_rect = unpressed_rect
	unpressed_rect.visible = true
	pressed_rect.visible = false
	pressed_active_rect.visible = false
	unpressed_active_rect.visible = false


func update_pitch_change(new_pitch_change):
	pitch_change = new_pitch_change
	$ClickDown.pitch_scale = new_pitch_change
	$ClickUp.pitch_scale = new_pitch_change


func _on_Events_hazard_tool_changed(new_hazard_id, new_hazard_direction):
	if new_hazard_id == hazard_id:
		if not active_tool:
			set_active()
	else:
		set_inactive()


func _on_Events_deactivate_tools():
	set_inactive()
