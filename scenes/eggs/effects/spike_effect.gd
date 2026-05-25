extends EggEffect

func activate(egg, direction):

	
	# SERVER ONLY
	

	if !multiplayer.is_server():
		return

	
	# GET LEVEL
	

	var level = (
		egg.get_tree()
		.get_first_node_in_group("level")
	)

	if level == null:
		return

	
	# NETWORK SPAWN SPIKE
	

	level.spawn_spike(
		egg.global_position,
		direction,
		egg.owner_peer_id
	)

	print(
		"Requested spike spawn for peer:",
		egg.owner_peer_id
	)
