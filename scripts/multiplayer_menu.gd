extends Control


func _on_host_button_pressed():

	print("Hosting game...")

	NetworkManager.host_game()

	get_tree().change_scene_to_file(
        "res://scenes/multiplayer.tscn"
	)


func _on_test_server_pressed():

	print("Joining game...")

	NetworkManager.join_game("127.0.0.1")

	get_tree().change_scene_to_file(
        "res://scenes/multiplayer.tscn"
	)


func _on_back_button_pressed():

	get_tree().change_scene_to_file(
        "res://scenes/Main_Menu.tscn"
	)
