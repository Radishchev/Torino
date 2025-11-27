extends CanvasLayer

@export var egg_icon: Texture2D

@onready var egg_container: HBoxContainer = $EggContainer
@onready var pause_menu: ColorRect = $PauseMenu
@onready var pause_button := $PauseButton

@onready var feather_container: HBoxContainer = $FeatherContainer 
@onready var feather_count_label: Label = $FeatherContainer/FeatherLabel


func _ready():
	update_feathers_collected(0)


func update_feathers_collected(collected_count: int):
	feather_count_label.text = "x " + str(collected_count)


func update_eggs_remaining(remaining: int):
	for child in egg_container.get_children():
		child.queue_free()

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
	pause_menu.visible = get_tree().paused
	print("Paused:", get_tree().paused)


func _on_resume_button_pressed():
	get_tree().paused = false
	pause_menu.visible = false


func _on_restart_button_pressed():
	get_tree().paused = false
	get_tree().reload_current_scene()


func _on_quite_button_pressed() -> void:
	get_tree().quit()
