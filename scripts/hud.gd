extends CanvasLayer

@export var egg_icon: Texture2D      # assign your egg sprite in the inspector
@onready var egg_container: HBoxContainer = $EggContainer


func update_eggs_remaining(remaining: int):
	# Remove old icons
	for child in egg_container.get_children():
		egg_container.remove_child(child)
		child.queue_free()

	# Add icons for remaining eggs
	for i in range(remaining):
		var icon = TextureRect.new()
		icon.texture = egg_icon
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.custom_minimum_size = Vector2(48, 48)
		egg_container.add_child(icon)


func _on_pause_pressed():
	get_tree().paused = not get_tree().paused


func _on_pause_button_pressed() -> void:
	get_tree().paused = not get_tree().paused
	print("Pause toggled:", get_tree().paused)
