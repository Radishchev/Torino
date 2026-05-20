extends EggEffect

func activate(egg, _direction):

	####################################################
	# SERVER ONLY
	####################################################

	if !multiplayer.is_server():
		return

	####################################################
	# GET LEVEL
	####################################################

	var level = (
		egg.get_tree()
		.get_first_node_in_group("level")
	)

	if level == null:
		return

	####################################################
	# FIND PLAYER
	####################################################

	var player = (
		level.players.get_node_or_null(
			str(egg.owner_peer_id)
		)
	)

	if player == null:
		return

	####################################################
	# SET RESPAWN EGG
	####################################################

	player.set_respawn_egg.rpc_id(
		player.get_multiplayer_authority(),
		egg.get_path(),
		egg.global_position
	)

	print(player.username, " set respawn egg")
