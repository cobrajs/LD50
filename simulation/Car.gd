extends PathFollow2D

onready var animation: AnimationPlayer = $AnimationPlayer
onready var car: Sprite = $CarSprite

export(int) var car_type = 0

func _ready():
	unit_offset = 0
	animation.play("ShowCar")
	
	car_type = (randi() % 2) * 4

## Move car along the path
## Update the car's rotation and frame to match the travel direction
func move_along(delta):
	var previous_position = get_global_position()
	offset += 200 * delta
	var new_position = get_global_position()
	var car_angle = rad2deg(new_position.angle_to_point(previous_position))
	if unit_offset >= 0.95 and not animation.is_playing():
		animation.play("HideCar")
	if car_angle <= 45 and car_angle >= -45: # Right
		car.frame = 1 + car_type
	elif car_angle > 45 and car_angle < 135: # Down
		car.frame = 3 + car_type
		car_angle -= 90
	elif (car_angle >= 135 and car_angle <= 180) or (car_angle <= -135 and car_angle >= -180): # Left
		car.frame = 2 + car_type
		if car_angle > 0:
			car_angle -= 180
		else:
			car_angle += 180
	elif car_angle < -45 and car_angle > -135:
		car.frame = 0 + car_type
		car_angle += 90

	car.rotation = deg2rad(car_angle)
