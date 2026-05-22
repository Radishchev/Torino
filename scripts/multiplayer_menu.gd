extends Control

@onready var games_container = $GamesContainer
@onready var username_input = $UsernameInput

var known_games := []

func _ready():

	####################################################
	# CONNECT SIGNAL
	####################################################

	if !NetworkManager.lan_games_updated.is_connected(
		refresh_games
	):
		NetworkManager.lan_games_updated.connect(
			refresh_games
		)

	####################################################
	# START DISCOVERY
	####################################################

	NetworkManager.call_deferred(
		"start_lan_discovery"
	)

####################################################
# REFRESH SERVER LIST
####################################################

func refresh_games():

	####################################################
	# CLEAR OLD BUTTONS
	####################################################
	print("Refreshing games UI")
	for child in games_container.get_children():

		child.queue_free()

	####################################################
	# REBUILD
	####################################################

	for ip in NetworkManager.discovered_games:
		print("Creating button for ", ip)
		var data = (
			NetworkManager.discovered_games[ip]
		)

		var button = Button.new()

		button.text = (
			data["name"]
		)

		button.custom_minimum_size = Vector2(
			0,
			50
		)

		button.pressed.connect(
			func():

				var username = (
					username_input.text
				)

				if username.strip_edges() == "":

					username = (
						NetworkManager
						.generate_random_username()
					)

				NetworkManager.player_username = username

				print(
					"Joining:",
					ip
				)

				NetworkManager.join_game(ip)

				get_tree().change_scene_to_file(
					"res://scenes/lobby.tscn"
				)
		)

		games_container.add_child(button)

####################################################
# PROCESS
####################################################

#func _process(_delta):
#
	#var current_games = (
		#NetworkManager
		#.discovered_games.keys()
	#)
#
	#if current_games != known_games:
#
		#known_games = current_games.duplicate()
#
		#refresh_games()

####################################################
# HOST BUTTON
####################################################

func _on_host_button_pressed():

	var username = username_input.text

	if username.strip_edges() == "":

		username = (
			NetworkManager
			.generate_random_username()
		)

	NetworkManager.player_username = username

	print("Hosting as:", username)
	
	NetworkManager.host_game()

	get_tree().change_scene_to_file(
		"res://scenes/lobby.tscn"
	)

####################################################
# BACK BUTTON
####################################################

func _on_back_button_pressed():

	get_tree().change_scene_to_file(
		"res://scenes/Main_Menu.tscn"
	)


func _on_refresh_button_pressed() -> void:
	refresh_games()

func _on_local_test_pressed() -> void:
	
	var username = username_input.text

	if username.strip_edges() == "":

		username = (
			NetworkManager
			.generate_random_username()
		)

	NetworkManager.player_username = username

	print("Joining localhost as:", username)

	NetworkManager.join_game("127.0.0.1")

	get_tree().change_scene_to_file(
		"res://scenes/lobby.tscn"
	)
