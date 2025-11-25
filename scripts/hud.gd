extends CanvasLayer

@export var egg_icon: Texture2D

@onready var egg_container: HBoxContainer = $EggContainer
@onready var pause_menu: ColorRect = $PauseMenu
@onready var pause_button := $PauseButton

func update_eggs_remaining(remaining: int):
	# Remove old icons
	for child in egg_container.get_children():
		egg_container.remove_child(child)
		child.queue_free()

	# Add icons
	for i in range(remaining):
		var icon = TextureRect.new()
		icon.texture = egg_icon
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.custom_minimum_size = Vector2(48, 48)
		egg_container.add_child(icon)


func _on_pause_button_pressed():
	toggle_pause()


func toggle_pause():
	get_tree().paused = not get_tree().paused
	pause_menu.visible = get_tree().paused   # show/hide menu
	print("Paused:", get_tree().paused)


# Resume Button
func _on_resume_button_pressed():
	get_tree().paused = false
	pause_menu.visible = false


# Restart Button
func _on_restart_button_pressed():
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_quite_button_pressed() -> void:
	get_tree().quit()
