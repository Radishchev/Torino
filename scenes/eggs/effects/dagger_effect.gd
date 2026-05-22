extends EggEffect

@export var duration := 7

func activate(egg, direction):

	print("Dagger effect activated")

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

	print(
		"Giving dagger to:",
		player.username
	)

	####################################################
	# ACTIVATE DAGGER
	####################################################

	if (
		player.get_multiplayer_authority()
		== multiplayer.get_unique_id()
	):

		player.activate_dagger(duration)

	else:

		player.activate_dagger.rpc_id(
			player.get_multiplayer_authority(),
			duration
		)
