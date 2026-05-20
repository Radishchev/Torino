extends Control

####################################################
# PLAYER
####################################################

var player

####################################################
# TEXTURES
####################################################

@export var heart_texture : Texture2D

####################################################
# NODES
####################################################

@onready var hearts_container = $HeartsContainer

@onready var egg_container = $EggContainer

@onready var leaderboard_entries = (
	$LeaderboardPanel/MarginContainer/LeaderboardEntries
)

####################################################
# READY
####################################################

func _ready():
	$LeaderboardPanel.visible = false
	
	update_leaderboard()
	
	if OS.has_feature("mobile"):

		$MobileControls.visible = true

	else:

		$MobileControls.visible = false

####################################################
# PLAYER SETUP
####################################################

func set_player(p):

	player = p

	print("HUD connected to:", player.name)

####################################################
# DEBUG
####################################################

func _process(delta):

	if player == null:
		return

	$DebugLabel.text = (
		"Player: " + player.name
	)

####################################################
# HEARTS
####################################################

func update_hearts(current, maximum):

	####################################################
	# REMOVE OLD HEARTS
	####################################################

	for child in hearts_container.get_children():

		child.queue_free()

	####################################################
	# CREATE HEARTS
	####################################################

	for i in range(maximum):

		var heart = TextureRect.new()

		heart.texture = heart_texture

		####################################################
		# HEART SIZE
		####################################################

		heart.custom_minimum_size = Vector2(42, 42)

		heart.expand_mode = (
			TextureRect.EXPAND_IGNORE_SIZE
		)

		heart.stretch_mode = (
			TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		)

		####################################################
		# EMPTY HEARTS
		####################################################

		if i >= current:

			heart.modulate.a = 0.25

		hearts_container.add_child(heart)

####################################################
# EGGS
####################################################

func update_eggs(egg_stack):

	####################################################
	# CLEAR OLD ICONS
	####################################################

	for child in egg_container.get_children():

		child.queue_free()

	####################################################
	# ADD EGG ICONS
	####################################################

	for egg_data in egg_stack:

		var icon = TextureRect.new()

		icon.texture = egg_data.icon

		icon.custom_minimum_size = Vector2(60, 60)

		icon.expand_mode = (
			TextureRect.EXPAND_IGNORE_SIZE
		)

		icon.stretch_mode = (
			TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		)

		egg_container.add_child(icon)

####################################################
# LEADERBOARD
####################################################
func show_leaderboard():

	$LeaderboardPanel.visible = true


func hide_leaderboard():

	$LeaderboardPanel.visible = false
	

func update_leaderboard():

	####################################################
	# CLEAR OLD ENTRIES
	####################################################

	for child in leaderboard_entries.get_children():

		child.queue_free()

	####################################################
	# SORT PLAYERS BY KILLS
	####################################################

	var sorted_players := []

	for peer_id in NetworkManager.player_kills:

		sorted_players.push_back({
			"peer_id": peer_id,
			"kills": NetworkManager.player_kills[peer_id]
		})

	sorted_players.sort_custom(
		func(a, b):
			return a["kills"] > b["kills"]
	)

	####################################################
	# CREATE UI LABELS
	####################################################

	for entry in sorted_players:

		var label = Label.new()

		var username = (
			NetworkManager.player_usernames.get(
				entry["peer_id"],
				"Player"
			)
		)

		####################################################
		# LEADERBOARD TEXT
		####################################################

		label.text = (
			username
			+ "  -  "
			+ str(entry["kills"])
		)

		####################################################
		# STYLE
		####################################################

		label.horizontal_alignment = (
			HORIZONTAL_ALIGNMENT_CENTER
		)

		label.add_theme_font_size_override(
			"font_size",
			18
		)

		leaderboard_entries.add_child(label)
