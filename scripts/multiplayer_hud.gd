extends Control

var player


func set_player(p):

	player = p

	print("HUD connected to:", player.name)


func _process(delta):

	if player == null:
		return

	$DebugLabel.text = (
		"Player: " + player.name
	)
