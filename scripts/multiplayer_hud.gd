extends Control

var player
@export var heart_texture : Texture2D

@onready var hearts_container = $HeartsContainer
@onready var egg_container = $EggContainer

func set_player(p):

	player = p

	print("HUD connected to:", player.name)


func _process(delta):

	if player == null:
		return

	$DebugLabel.text = (
		"Player: " + player.name
	)

func update_hearts(current, maximum):

	# Remove old hearts
	for child in hearts_container.get_children():

		child.queue_free()

	# Create hearts
	for i in range(maximum):

		var heart = TextureRect.new()

		heart.texture = heart_texture

		# Heart size
		heart.custom_minimum_size = Vector2(42, 42)

		heart.expand_mode = TextureRect.EXPAND_IGNORE_SIZE

		heart.stretch_mode = (
			TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		)

		# Empty hearts become transparent
		if i >= current:

			heart.modulate.a = 0.25

		hearts_container.add_child(heart)


func update_eggs(egg_stack):

	# Clear old icons
	for child in egg_container.get_children():

		child.queue_free()

	# Add egg icons
	for egg_data in egg_stack:

		var icon = TextureRect.new()

		icon.texture = egg_data.icon

		icon.custom_minimum_size = Vector2(32, 32)

		icon.expand_mode = (
			TextureRect.EXPAND_IGNORE_SIZE
		)

		icon.stretch_mode = (
			TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		)

		egg_container.add_child(icon)
