extends Area2D

@export var trigger_room_overview := true
@export var overview_only_once := true

var triggered := false

func _ready():
	print("RoomC ready")
	area_entered.connect(_on_area_entered)


func _on_area_entered(area):

	print("Area entered:", area.name)

	print("Entered by:", area)

	if overview_only_once and triggered:
		return

	triggered = true

	print("Player entered RoomC")

	var camera = get_viewport().get_camera_2d()

	var room_size = _get_room_size()
	var room_center = global_position

	camera.set_room(room_center, room_size)

	if trigger_room_overview:
		await camera.show_room_overview(room_center)


func _get_room_size() -> Vector2:

	var shape = $CollisionShape2D.shape

	if shape is RectangleShape2D:
		return shape.size

	return Vector2.ZERO
