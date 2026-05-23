extends Control

@onready var player_list = $PlayerList
@onready var start_button = $StartButton
@onready var match_length_option = $MatchLengthOption

var displayed_players := []

func _ready():

	print("Lobby loaded")

	####################################################
	# ONLY HOST CAN START
	####################################################

	start_button.visible = (
		multiplayer.is_server()
	)

	match_length_option.visible = (
		multiplayer.is_server()
	)

func _process(_delta):

	var current_players = (
		NetworkManager
		.lobby_players
		.keys()
	)

	if current_players != displayed_players:

		displayed_players = (
			current_players.duplicate()
		)

		refresh_player_list()

func refresh_player_list():

	####################################################
	# CLEAR OLD LABELS
	####################################################

	for child in player_list.get_children():

		child.queue_free()

	####################################################
	# CREATE PLAYER LABELS
	####################################################

	for peer_id in (
		NetworkManager.lobby_players
	):

		var username = (
			NetworkManager
			.lobby_players[peer_id]
		)

		var label = Label.new()

		label.text = username
		
		if peer_id == 1:

			label.text = (
				username + " (Host)"
			)

		else:

			label.text = username
			
		player_list.add_child(label)

func _on_start_button_pressed():

	if !multiplayer.is_server():
		return

	####################################################
	# MATCH TIMER
	####################################################

	var durations = [
		60,
		180,
		300,
		600
	]

	NetworkManager.match_duration = (
		durations[
			match_length_option.selected
		]
	)

	print(
		"Selected match duration:",
		NetworkManager.match_duration
	)

	####################################################
	# LOAD GAME FOR EVERYONE
	####################################################
	NetworkManager.current_match_state = (
		NetworkManager.MatchState.IN_GAME
	)
	
	NetworkManager.start_match.rpc()

func _on_leave_button_pressed():

	####################################################
	# CLOSE CONNECTION
	####################################################

	if multiplayer.multiplayer_peer:

		multiplayer.multiplayer_peer.close()

	####################################################
	# CLEAR LOBBY DATA
	####################################################

	NetworkManager.lobby_players.clear()

	####################################################
	# RETURN TO MENU
	####################################################

	get_tree().change_scene_to_file(
		"res://scenes/multiplayer_menu.tscn"
	)
