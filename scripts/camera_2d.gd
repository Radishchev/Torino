extends Camera2D

@export var follow_smoothing: float = 0.1   # from 0 to 1
var smoothing: float

var current_room_center: Vector2
var current_room_size: Vector2

@onready var view_size: Vector2 = get_viewport_rect().size
var zoom_view_size: Vector2


func _ready():
	Globals.register_camera(self)

	position_smoothing_enabled = false
	smoothing = 1.0
	await get_tree().create_timer(0.1).timeout
	smoothing = follow_smoothing



func _physics_process(delta: float) -> void:
	zoom_view_size = view_size * zoom

	var target_position := calculate_target_position(current_room_center, current_room_size)

	# Smooth camera movement
	position = position.lerp(target_position, smoothing)


func calculate_target_position(room_center: Vector2, room_size: Vector2) -> Vector2:
	var x_margin: float = (room_size.x - zoom_view_size.x) / 2.0
	var y_margin: float = (room_size.y - zoom_view_size.y) / 2.0

	var result := Vector2.ZERO

	# X axis constraint
	if x_margin <= 0:
		result.x = room_center.x
	else:
		var left_limit: float = room_center.x - x_margin
		var right_limit: float = room_center.x + x_margin
		result.x = clamp(Globals.platforming_player.global_position.x, left_limit, right_limit)

	# Y axis constraint
	if y_margin <= 0:
		result.y = room_center.y
	else:
		var top_limit: float = room_center.y - y_margin
		var bottom_limit: float = room_center.y + y_margin
		result.y = clamp(Globals.platforming_player.global_position.y, top_limit, bottom_limit)

	return result
