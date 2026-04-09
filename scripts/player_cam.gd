extends Camera2D

@export var follow_smoothing: float = 0.12
@export var snap_on_room_change: bool = true
@export var overview_duration := 1.0
@export var overview_pause := 1.5

var smoothing: float = 1.0

var cinematic_mode := false
var normal_zoom := Vector2.ONE
var overview_played := false

var current_room_center: Vector2 = Vector2.ZERO
var current_room_size: Vector2 = Vector2.ZERO

var view_size: Vector2 = Vector2.ZERO
var zoom_view_size: Vector2 = Vector2.ZERO


func _ready() -> void:

	view_size = get_viewport_rect().size
	normal_zoom = zoom

	var player = get_tree().current_scene.get_node("Player")
	player.room_changed.connect(_on_room_changed)

	smoothing = 1.0
	await get_tree().create_timer(0.05).timeout
	smoothing = follow_smoothing


func _physics_process(delta: float) -> void:

	if cinematic_mode:
		return

	view_size = get_viewport_rect().size
	zoom_view_size = view_size * (1.0 / zoom.x)

	if current_room_size == Vector2.ZERO:
		return

	var target := _calculate_target_position(current_room_center, current_room_size)

	if smoothing >= 1.0:
		global_position = target
	else:
		global_position = global_position.lerp(
			target,
			clamp(smoothing * delta * 60.0, 0.0, 1.0)
		)


func _on_room_changed(room_center: Vector2, room_size: Vector2, room_area: Area2D) -> void:

	set_room(room_center, room_size)

	# Only trigger overview for RoomC
	if room_area.name == "RoomC" and not overview_played:

		overview_played = true
		await show_room_overview(room_center, room_size)


func set_room(room_center: Vector2, room_size: Vector2) -> void:

	current_room_center = room_center
	current_room_size = room_size

	_update_camera_limits(room_center, room_size)

	if snap_on_room_change:
		global_position = _calculate_target_position(room_center, room_size)
		reset_smoothing()


func show_room_overview(room_center: Vector2, room_size: Vector2) -> void:

	cinematic_mode = true
	normal_zoom = zoom

	var player = get_tree().current_scene.get_node("Player")

	# Disable player control
	player.set_physics_process(false)
	player.set_process(false)

	# Calculate automatic zoom to fit room
	var screen_size = get_viewport_rect().size

	var zoom_x = screen_size.x / room_size.x
	var zoom_y = screen_size.y / room_size.y

	var zoom_value = min(zoom_x, zoom_y)
	var target_zoom = Vector2(zoom_value, zoom_value)

	# -------- ZOOM OUT + PAN TO CENTER (SIMULTANEOUS) --------
	var tween := create_tween()

	tween.set_parallel(true)

	tween.tween_property(self, "global_position", room_center, 1.2)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)

	tween.tween_property(self, "zoom", target_zoom, 1.2)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)

	await tween.finished

	# -------- SHOW OVERVIEW FOR 6 SECONDS --------
	await get_tree().create_timer(6.0).timeout

	# -------- RETURN TO PLAYER (PAN + ZOOM TOGETHER) --------
	var return_tween := create_tween()
	return_tween.set_parallel(true)

	return_tween.tween_property(self, "zoom", normal_zoom, 1.2)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)

	return_tween.tween_property(self, "global_position", player.global_position, 1.2)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)

	await return_tween.finished

	# -------- WAIT BEFORE RESUMING GAME --------
	await get_tree().create_timer(1.5).timeout

	player.set_physics_process(true)
	player.set_process(true)

	cinematic_mode = false

func _calculate_target_position(room_center: Vector2, room_size: Vector2) -> Vector2:

	var player_node := get_tree().current_scene.get_node_or_null("Player")

	var p := room_center
	if player_node != null:
		p = player_node.global_position

	var x_margin := room_size.x - zoom_view_size.x
	var y_margin := room_size.y - zoom_view_size.y

	var result := p

	if x_margin <= 0.0:
		result.x = room_center.x
	else:
		var half_margin = x_margin * 0.5
		var left_limit = room_center.x - half_margin
		var right_limit = room_center.x + half_margin
		result.x = clamp(p.x, left_limit, right_limit)

	if y_margin <= 0.0:
		result.y = room_center.y
	else:
		var half_margin = y_margin * 0.5
		var top_limit = room_center.y - half_margin
		var bottom_limit = room_center.y + half_margin
		result.y = clamp(p.y, top_limit, bottom_limit)

	return result


func _update_camera_limits(room_center: Vector2, room_size: Vector2) -> void:

	var half_room := room_size * 0.5

	limit_left = int(room_center.x - half_room.x)
	limit_right = int(room_center.x + half_room.x)
	limit_top = int(room_center.y - half_room.y)
	limit_bottom = int(room_center.y + half_room.y)
