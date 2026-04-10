extends Node


func _on_button_pressed() -> void:

	# If a save file exists
	if FileAccess.file_exists("user://save.dat"):

		var file = FileAccess.open("user://save.dat", FileAccess.READ)
		var save_data = file.get_var()

		var level_path = save_data["level"]

		print("Loading saved level:", level_path)

		get_tree().change_scene_to_file(level_path)

	else:

		print("No save found, starting new game")

		get_tree().change_scene_to_file("res://scenes/level_1.tscn")


func _on_button_2_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Setting.tscn")
	
func _on_play_friends_button_pressed() -> void:

	# Hide main menu buttons
	$Button.visible = false
	$PlayFriendsButton.visible = false

	# Show multiplayer options
	$MultiplayerPanel.visible = true

func _on_host_button_pressed():

	var player_name = $MultiplayerPanel/LineEdit.text
	if player_name == "":
		player_name = "Player"

	NetworkManager.host_game()

	get_tree().change_scene_to_file("res://scenes/level_1.tscn")

func _on_join_button_pressed():

	var ip = $MultiplayerPanel/LineEdit.text
	if ip == "":
		ip = "127.0.0.1"

	NetworkManager.join_game(ip)

	get_tree().change_scene_to_file("res://scenes/level_1.tscn")
