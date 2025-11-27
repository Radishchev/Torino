extends Area2D

signal room_changed(room_area: Area2D)

func _on_area_entered(area: Area2D) -> void:
	if area.name.begins_with("Room"): # "Room1", "RoomA" etc.
		emit_signal("room_changed", area)
