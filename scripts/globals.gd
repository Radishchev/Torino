extends Node

var player_camera: Camera2D = null
var platforming_player: CharacterBody2D = null

var room_pause: bool = false
@export var room_pause_time: float = 0.2


func register_camera(cam: Camera2D):
	player_camera = cam


func register_player(p):
	platforming_player = p


func change_room(room_center: Vector2, room_size: Vector2) -> void:
	if player_camera == null:
		push_warning("Camera not registered!")
		return

	player_camera.current_room_center = room_center
	player_camera.current_room_size = room_size

	room_pause = true
	await get_tree().create_timer(room_pause_time).timeout
	room_pause = false
