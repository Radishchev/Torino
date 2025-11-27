extends Camera2D

@export var follow_smoothing: float = 0.12
@export var snap_on_room_change: bool = true 

var smoothing: float = 1.0

# Room data
var current_room_center: Vector2 = Vector2.ZERO
var current_room_size: Vector2 = Vector2.ZERO

var view_size: Vector2 = Vector2.ZERO
var zoom_view_size: Vector2 = Vector2.ZERO

func _ready() -> void:
	view_size = get_viewport_rect().size
	smoothing = 1.0
	await get_tree().create_timer(0.05).timeout
	smoothing = follow_smoothing

func _physics_process(delta: float) -> void:
	# Update view size in case of window resize
	view_size = get_viewport_rect().size
	zoom_view_size = view_size * (1.0 / zoom.x) # Correct zoom calculation for View size coverage

	if current_room_size == Vector2.ZERO:
		return

	# Calculate ideal target
	var target := _calculate_target_position(current_room_center, current_room_size)
	
	# Apply movement
	if smoothing >= 1.0:
		global_position = target
	else:
		global_position = global_position.lerp(target, clamp(smoothing * delta * 60.0, 0.0, 1.0))
	
	# REMOVED: Manual clamping of global_position against limits.
	# Godot's internal engine code automatically prevents the camera 
	# from rendering outside the 'limit_*' properties we set below.

func set_room(room_center: Vector2, room_size: Vector2) -> void:
	current_room_center = room_center
	current_room_size = room_size
	
	_update_camera_limits(room_center, room_size)

	if snap_on_room_change:
		# Snap immediately to target
		global_position = _calculate_target_position(current_room_center, current_room_size)
		# Reset_smoothing handles the internal physics interpolation of the engine
		reset_smoothing() 

func _calculate_target_position(room_center: Vector2, room_size: Vector2) -> Vector2:
	var player_node := get_tree().current_scene.get_node_or_null("Player")
	var p := room_center
	
	if player_node != null:
		p = player_node.global_position

	# Calculate available movement space (Room Size - View Size)
	var x_margin := room_size.x - zoom_view_size.x
	var y_margin := room_size.y - zoom_view_size.y
	
	var result := p

	# If room is smaller than view, center strictly on room
	# If room is larger, clamp player position within the "Safe Center Zone"
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
	
	# --- MAJOR FIX HERE ---
	# We assign the Raw Edges of the room to the limits.
	# We do NOT add/subtract half_view.
	
	limit_left = int(room_center.x - half_room.x)
	limit_right = int(room_center.x + half_room.x)
	limit_top = int(room_center.y - half_room.y)
	limit_bottom = int(room_center.y + half_room.y)
