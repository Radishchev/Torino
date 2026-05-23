extends Control

####################################################
# PLAYER
####################################################

var player
var mobile_controls_enabled := false

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

@onready var pause_menu = $PauseMenu

@onready var mobile_controls = $MobileControls

@onready var timer_label = $TimerLabel

@onready var leaderboard_panel = $LeaderboardPanel

@onready var death_label = $DeathLabel

@onready var kills_label = $KillsLabel
####################################################
# READY
####################################################

func _ready():
	leaderboard_panel.visible = false
	
	update_leaderboard()
	
	mobile_controls_enabled = (
		OS.has_feature("mobile")
	)

	mobile_controls.visible = (
		mobile_controls_enabled
	)

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
	var time_left = (
		NetworkManager.current_match_time
	)

	var minutes = int(time_left / 60)

	var seconds = int(time_left % 60)

	timer_label.text = (
		"%02d:%02d"
		% [minutes, seconds]
	)
	
	####################################################
	# LOCAL PLAYER KILLS
	####################################################

	if multiplayer.has_multiplayer_peer():

		var local_id = (
			multiplayer.get_unique_id()
		)

		var kills = (
			NetworkManager.player_kills.get(
				local_id,
				0
			)
		)

		kills_label.text = (
			"Kills: " + str(kills)
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

	leaderboard_panel.visible = true
	death_label.visible = true


func hide_leaderboard():

	leaderboard_panel.visible = false
	death_label.visible = false
	

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


func _on_pause_button_pressed():

	open_pause_menu()

	
func _unhandled_input(event):

	if event.is_action_pressed("ui_cancel"):

		if pause_menu.visible:

			close_pause_menu()

		else:

			open_pause_menu()


func _on_resume_button_released() -> void:

	close_pause_menu()


func _on_leave_button_released() -> void:
	####################################################
	# CLOSE CONNECTION
	####################################################

	if multiplayer.multiplayer_peer:

		multiplayer.multiplayer_peer.close()

	####################################################
	# RETURN TO MENU
	####################################################

	get_tree().change_scene_to_file(
		"res://scenes/Main_Menu.tscn"
	)


func open_pause_menu():

	pause_menu.visible = true

	####################################################
	# HIDE GAMEPLAY UI
	####################################################

	hearts_container.visible = false

	egg_container.visible = false

	mobile_controls.visible = false

	$PauseButton.visible = false
	
	leaderboard_panel.visible = false


func close_pause_menu():

	pause_menu.visible = false

	####################################################
	# RESTORE GAMEPLAY UI
	####################################################

	hearts_container.visible = true

	egg_container.visible = true

	mobile_controls.visible = (
		mobile_controls_enabled
	)

	$PauseButton.visible = true


func show_match_finished(winner_name):

	####################################################
	# SHOW LEADERBOARD
	####################################################

	show_leaderboard()

	####################################################
	# MATCH END TEXT
	####################################################

	death_label.visible = true

	death_label.text = (
		"Match Finished\n"
		+ winner_name
		+ " Won!"
	)
