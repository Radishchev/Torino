extends Control


func _on_host_button_pressed():

	var username = $UsernameInput.text

	# Generate random username if empty
	if username.strip_edges() == "":
		username = NetworkManager.generate_random_username()

	# Save username
	NetworkManager.player_username = username

	print("Hosting as:", username)

	NetworkManager.host_game()

	get_tree().change_scene_to_file(
		"res://scenes/multiplayer.tscn"
	)


func _on_test_server_pressed():

	var username = $UsernameInput.text

	# Generate random username if empty
	if username.strip_edges() == "":
		username = NetworkManager.generate_random_username()

	# Save username
	NetworkManager.player_username = username

	print("Joining as:", username)

	NetworkManager.join_game("127.0.0.1")

	get_tree().change_scene_to_file(
		"res://scenes/multiplayer.tscn"
	)


func _on_back_button_pressed():

	get_tree().change_scene_to_file(
		"res://scenes/Main_Menu.tscn"
	)
