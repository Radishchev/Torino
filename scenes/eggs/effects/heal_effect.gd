extends EggEffect

@export var heal_amount := 2

func activate(egg, direction):

	print("Healing effect activated")

	print(
		"Egg owner peer id:",
		egg.owner_peer_id
	)

	
	# GET LEVEL
	

	var level = (
		egg.get_tree()
		.get_first_node_in_group("level")
	)

	if level == null:

		print("No level found")
		return

	print("Level found")

	
	# FIND PLAYER
	

	var player = (
		level.players.get_node_or_null(
			str(egg.owner_peer_id)
		)
	)

	if player == null:

		print(
			"Could not find player:",
			egg.owner_peer_id
		)

		return

	print(
		"Found player:",
		player.username
	)

	print(
		"Health before:",
		player.health
	)

	
	# HEAL
	

	if player.get_multiplayer_authority() == multiplayer.get_unique_id():

		player.heal(heal_amount)

	else:

		player.heal.rpc_id(
			player.get_multiplayer_authority(),
			heal_amount
		)

	print(
		"Health after:",
		player.health
	)
