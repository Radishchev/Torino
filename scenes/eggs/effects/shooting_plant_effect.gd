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

	
	# SPAWN SHOOTING PLANT
	

	level.spawn_shooting_plant(
		egg.global_position,
		direction,
		egg.owner_peer_id
	)

	print(
		"Requested shooting plant spawn for peer:",
		egg.owner_peer_id
	)
