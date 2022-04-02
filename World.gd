extends Control

# Game elements
onready var road = $Road
onready var path_shower = $PathShower


func _ready():
	Events.connect("show_path", self, "_on_Events_show_path")


func _on_Events_show_path(path: PoolVector2Array):
	path_shower.clear()
	if path != null:
		for point in path:
			path_shower.set_cellv(point, 0)
		path_shower.update_bitmask_region()

