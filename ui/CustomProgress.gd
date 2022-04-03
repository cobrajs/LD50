extends Control


export var min_value = 0 setget update_min_value
export var max_value = 100 setget update_max_value
export var step = 1 setget update_step
export var value = 50 setget update_value

export(Color) var border_color = Color.darkslategray setget update_border_color
export(Color) var progress_color = Color.darkcyan setget update_progress_color

export(float) var border_width := 2.0 setget update_border_width

export(Texture) var min_texture : Texture setget update_min_texture
export(Texture) var max_texture : Texture setget update_max_texture

func _ready():
	set_custom_minimum_size(Vector2(30, 30))


func _draw():
	## Draw progress
	var length = max_value - min_value
	var scale = rect_size.x / length
	var middle = length / 2
	var start = min_value
	var end = value
	if min_value < 0:
		if value < 0:
			start = middle + value
			end = middle
		else:
			start = middle
			end = middle + value
			
	draw_rect(Rect2(start * scale, 0, (end - start) * scale, rect_size.y), progress_color)
	draw_rect(Rect2(Vector2.ZERO, rect_size), border_color, false, 2.0)
	
	if min_texture:
		draw_texture(min_texture, Vector2(0, rect_size.y / 2 - min_texture.get_height() / 2))
	
	if max_texture:
		draw_texture(max_texture, Vector2(rect_size.x - max_texture.get_width() - 2, rect_size.y / 2 - max_texture.get_height() / 2))


func update_min_value(new_min_value):
	min_value = new_min_value
	update()


func update_max_value(new_max_value):
	max_value = new_max_value
	update()


func update_step(new_step):
	step = new_step
	update()


func update_value(new_value):
	value = min(max_value, max(min_value, new_value))
	update()


func update_border_color(new_border_color):
	border_color = new_border_color
	update()


func update_progress_color(new_progress_color):
	progress_color = new_progress_color
	update()


func update_border_width(new_border_width):
	border_width = new_border_width
	update()


func update_min_texture(new_min_texture):
	min_texture = new_min_texture
	update()


func update_max_texture(new_max_texture):
	max_texture = new_max_texture
	update()
