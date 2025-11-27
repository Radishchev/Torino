extends Area2D

signal collected

func _ready():
	# Connect built-in body_entered signal
	body_entered.connect(_on_body_entered)

	# Auto-connect feather → player
	var player = get_tree().current_scene.get_node("Player")  # adjust if needed
	if player:
		var callable = Callable(player, "_on_feather_collected")
		if not collected.is_connected(callable):
			collected.connect(callable)


func _on_body_entered(body):
	if body.is_in_group("bird"):
		emit_signal("collected")
		print("feather collected")
		queue_free()
