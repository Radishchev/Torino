extends Node2D


####################################################
# SCENES
####################################################

const PLAYER_SCENE = preload(
	"res://scenes/multiplayer_player.tscn"
)

const EGG_SCENE = preload(
	"res://scenes/eggs/egg_object.tscn"
)

const SPIKE_SCENE = preload(
	"res://scenes/spike.tscn"
)

const SHOOTING_PLANT_SCENE = preload(
	"res://scenes/shooting_plant.tscn"
)

const BULLET_SCENE = preload(
	"res://scenes/bullet.tscn"
)


####################################################
# TEST EGG DATA
####################################################

const HEAL_EGG = preload(
	"res://scenes/eggs/resources/heal_egg.tres"
)

const SPIKE_EGG = preload(
	"res://scenes/eggs/resources/spike_egg.tres"
)

const SHOOTING_PLANT_EGG = preload(
	"res://scenes/eggs/resources/shooting_plant_egg.tres"
)

const RESPAWN_EGG = preload(
	"res://scenes/eggs/resources/respawn_egg.tres"
)

const DAGGER_EGG = preload(
	"res://scenes/eggs/resources/dagger_egg.tres"
)

####################################################
# RANDOM EGG POOL
####################################################

var egg_pool = [
	HEAL_EGG,
	SPIKE_EGG,
	SHOOTING_PLANT_EGG,
	RESPAWN_EGG,
	DAGGER_EGG
]
####################################################
# NODES
####################################################
@onready var players = $Players
@onready var player_spawner = $MultiplayerSpawner
@onready var spawn_points = $SpawnPoints

@onready var eggs = $Eggs
@onready var egg_spawns = $EggSpawns
@onready var egg_spawner = $EggSpawner

@onready var spike_spawner = $SpikeSpawner

@onready var shooting_plant_spawner = $ShootingPlantSpawner
@onready var bullet_spawner = $BulletSpawner

####################################################
# EGG SPAWNING
####################################################

var max_world_eggs := 7

var egg_spawn_interval := 8.0


var match_time_left := 0

var match_finished := false
####################################################
# READY
####################################################

func _ready():

	add_to_group("level")

	####################################################
	# MULTIPLAYER SPAWNERS
	####################################################

	player_spawner.spawn_function = (
		spawn_network_player
	)

	egg_spawner.spawn_function = (
		spawn_network_egg
	)

	spike_spawner.spawn_function = (
		spawn_network_spike
	)

	shooting_plant_spawner.spawn_function = (
		spawn_network_shooting_plant
	)

	bullet_spawner.spawn_function = (
		spawn_network_bullet
	)

	####################################################
	# SERVER CONNECTION EVENTS
	####################################################

	if multiplayer.is_server():
	
		match_time_left = (
			NetworkManager.match_duration
		)

		start_match_timer()
		
		multiplayer.peer_connected.connect(
			_on_peer_connected
		)

		multiplayer.peer_disconnected.connect(
			_on_peer_disconnected
		)

		####################################################
		# WAIT FOR SPAWNERS
		####################################################

		await get_tree().process_frame

		####################################################
		# SPAWN EXISTING PLAYERS
		####################################################

		for peer_id in (
			NetworkManager.player_usernames.keys()
		):

			spawn_player(peer_id)

		####################################################
		# STARTING EGGS
		####################################################

		spawn_starting_eggs()

		start_egg_spawn_loop()


####################################################
# PEER CONNECTIONS
####################################################

func _on_peer_connected(peer_id):

	print(
		"Peer connected:",
		peer_id
	)

	await get_tree().process_frame

	spawn_player(peer_id)

func _on_peer_disconnected(peer_id):

	print(
		"Peer disconnected:",
		peer_id
	)

	####################################################
	# SERVER ONLY
	####################################################

	if !multiplayer.is_server():
		return

	####################################################
	# REMOVE PLAYER
	####################################################

	if players.has_node(str(peer_id)):

		players.get_node(
			str(peer_id)
		).queue_free()
		
####################################################
# PLAYER SPAWNING
####################################################

####################################################
# PLAYER SPAWNING
####################################################

func spawn_player(peer_id):

	####################################################
	# SERVER ONLY
	####################################################

	if !multiplayer.is_server():
		return

	####################################################
	# ALREADY EXISTS
	####################################################

	if players.has_node(str(peer_id)):
		return

	print(
		"SERVER spawning player:",
		peer_id
	)

	####################################################
	# SPAWN THROUGH MULTIPLAYERSPAWNER
	####################################################

	player_spawner.spawn({
		"peer_id": peer_id
	})

####################################################
# NETWORK PLAYER SPAWN
####################################################

func spawn_network_player(data):

	var peer_id = int(
		data["peer_id"]
	)

	print(
		"Spawn network player:",
		peer_id,
		" on peer:",
		multiplayer.get_unique_id()
	)

	####################################################
	# CREATE PLAYER
	####################################################

	var player = (
		PLAYER_SCENE.instantiate()
	)

	####################################################
	# IMPORTANT
	####################################################

	player.name = str(peer_id)

	player.set_multiplayer_authority(
		peer_id,
		true
	)

	####################################################
	# USERNAME
	####################################################

	player.username = (
		NetworkManager
		.player_usernames
		.get(peer_id, "Player")
	)

	####################################################
	# FIND FREE SPAWN POINT
	####################################################

	var available_spawns = []

	####################################################
	# CHECK ALL SPAWN POINTS
	####################################################

	for spawn_point in spawn_points.get_children():

		var occupied := false

		####################################################
		# CHECK EXISTING PLAYERS
		####################################################

		for existing_player in players.get_children():

			if (
				existing_player.global_position
				.distance_to(
					spawn_point.global_position
				) < 8.0
			):

				occupied = true
				break

		####################################################
		# STORE FREE SPAWN
		####################################################

		if !occupied:

			available_spawns.append(
				spawn_point
			)

	####################################################
	# USE FREE SPAWN
	####################################################

	if available_spawns.size() > 0:

		var selected_spawn = (
			available_spawns[0]
		)

		player.global_position = (
			selected_spawn.global_position
		)

	####################################################
	# ALL OCCUPIED
	# USE RANDOM SPAWN
	####################################################

	else:

		var random_spawn = (
			spawn_points
			.get_children()
			.pick_random()
		)

		player.global_position = (
			random_spawn.global_position
	)

	print(
		"Player spawned at:",
		player.global_position
	)

	####################################################
	# IMPORTANT
	# DO NOT add_child()
	####################################################

	return player

####################################################
# RANDOM EGG SELECTION
####################################################

func get_random_egg():

	var weighted_pool = []

	for egg in egg_pool:

		for i in egg.rarity:

			weighted_pool.append(egg)

	return weighted_pool.pick_random()

####################################################
# RANDOM POSITION
####################################################

func get_random_egg_position():

	return Vector2(

		randf_range(32, 1136),

		randf_range(32, 624)
	)
	
####################################################
# STARTING EGGS
####################################################

func spawn_starting_eggs():

	####################################################
	# OLD MANUAL SPAWNING
	####################################################

	#for spawn in egg_spawns.get_children():
#
		#spawn_egg(
			#SHOOTING_PLANT_EGG,
			#spawn.global_position
		#)

	####################################################
	# RANDOM SPAWNING
	####################################################

	var egg_count := 4

	for i in egg_count:

		var egg_data = (
			get_random_egg()
		)

		var position = (
			get_random_egg_position()
		)

		spawn_egg(
			egg_data,
			position
		)

####################################################
# NETWORK EGG SPAWNING
####################################################

func start_egg_spawn_loop():

	while true:

		await get_tree().create_timer(
			egg_spawn_interval
		).timeout

		####################################################
		# SERVER ONLY
		####################################################

		if !multiplayer.is_server():
			return

		####################################################
		# COUNT WORLD EGGS
		####################################################

		var current_eggs = (
			eggs.get_child_count()
		)

		####################################################
		# LIMIT
		####################################################

		if current_eggs >= max_world_eggs:
			continue

		####################################################
		# SPAWN RANDOM EGG
		####################################################

		var egg_data = (
			get_random_egg()
		)

		var position = (
			get_random_egg_position()
		)

		spawn_egg(
			egg_data,
			position
		)

		print(
			"Spawned random egg"
		)
func spawn_egg(
	egg_data : EggData,
	position : Vector2,
	start_velocity := Vector2.ZERO,
	owner_peer_id := 1
):

	####################################################
	# ONLY SERVER SPAWNS
	####################################################

	if !multiplayer.is_server():
		return

	####################################################
	# UNIQUE NETWORK NAME
	####################################################

	var egg_name = (
		"Egg_"
		+ str(Time.get_ticks_usec())
	)

	####################################################
	# MultiplayerSpawner handles replication
	####################################################

	egg_spawner.spawn({
		"name": egg_name,
		"egg_resource_path": egg_data.resource_path,
		"position": position,
		"velocity": start_velocity,
		"owner_peer_id": owner_peer_id
	})

####################################################
# CALLED AUTOMATICALLY ON ALL PEERS
####################################################
func spawn_network_egg(data):

	####################################################
	# DEBUG
	####################################################

	print("Spawn data:", data)

	var egg = EGG_SCENE.instantiate()

	egg.pickup_blocked = true

	####################################################
	# IMPORTANT
	# DETERMINISTIC NAME
	####################################################

	egg.name = data["name"]

	####################################################
	# LOAD EGG DATA
	####################################################

	var egg_data = load(
		data["egg_resource_path"]
	)

	egg.egg_data = egg_data

	####################################################
	# IMPORTANT
	# STORE THROWER
	####################################################

	print(
		"DATA owner:",
		data["owner_peer_id"]
	)

	egg.owner_peer_id = int(
		data["owner_peer_id"]
	)

	print(
		"EGG owner AFTER assignment:",
		egg.owner_peer_id
	)

	####################################################
	# TRANSFORM
	####################################################

	egg.global_position = data["position"]

	egg.linear_velocity = data["velocity"]
	
	####################################################
	# STATIC WORLD EGGS
	####################################################

	if data["velocity"] == Vector2.ZERO:

		egg.freeze = true
		egg.world_spawned = true
		
	####################################################
	# PICKUP DELAY
	####################################################

	var timer = get_tree().create_timer(0.35)

	timer.timeout.connect(
		egg.unblock_pickup
	)

	####################################################
	# DEBUG
	####################################################

	print(
		"Spawned network egg at ",
		data["position"]
	)

	####################################################
	# IMPORTANT
	# DO NOT add_child() manually here.
	# MultiplayerSpawner already does that.
	####################################################

	return egg


func spawn_spike(
	position : Vector2,
	direction : Vector2,
	owner_peer_id : int
):

	####################################################
	# ONLY SERVER SPAWNS
	####################################################

	if !multiplayer.is_server():
		return

	####################################################
	# UNIQUE NAME
	####################################################

	var spike_name = (
		"Spike_"
		+ str(Time.get_ticks_usec())
	)

	####################################################
	# SPAWN THROUGH MULTIPLAYER SPAWNER
	####################################################

	spike_spawner.spawn({
		"name": spike_name,
		"position": position,
		"direction": direction,
		"owner_peer_id": owner_peer_id
	})
	
func spawn_network_spike(data):

	print("Spike spawn data:", data)

	####################################################
	# ROOT CONTAINER
	####################################################

	var root = Node2D.new()

	root.name = data["name"]

	####################################################
	# DATA
	####################################################

	var direction = data["direction"]

	var perpendicular = Vector2(
		-direction.y,
		direction.x
	)

	####################################################
	# CREATE 5 SPIKES
	####################################################

	for i in range(-2, 3):

		var spike = SPIKE_SCENE.instantiate()
		
		spike.z_index = -1
		
		root.add_child(spike)

		####################################################
		# POSITION
		####################################################

		var offset = perpendicular * i * 14.0

		spike.global_position = (
			data["position"]
			+ offset
			- (direction * 6)
		)

		####################################################
		# ROTATION
		####################################################

		spike.rotation = (
			Vector2.UP.angle_to(direction)
		)

		####################################################
		# SCALE
		####################################################

		spike.scale = Vector2(0.7, 0.7)

		####################################################
		# OWNER
		####################################################

		spike.owner_peer_id = int(
			data["owner_peer_id"]
		)

		print(
			"Spawned network spike for peer:",
			spike.owner_peer_id
		)

	return root


func spawn_shooting_plant(
	position : Vector2,
	direction : Vector2,
	owner_peer_id : int
):

	####################################################
	# ONLY SERVER SPAWNS
	####################################################

	if !multiplayer.is_server():
		return

	####################################################
	# UNIQUE NAME
	####################################################

	var plant_name = (
		"ShootingPlant_"
		+ str(Time.get_ticks_usec())
	)

	####################################################
	# SPAWN THROUGH MULTIPLAYER SPAWNER
	####################################################

	shooting_plant_spawner.spawn({
		"name": plant_name,
		"position": position,
		"direction": direction,
		"owner_peer_id": owner_peer_id
	})

func spawn_network_shooting_plant(data):

	print(
		"Shooting plant spawn data:",
		data
	)

	####################################################
	# CREATE PLANT
	####################################################

	var plant = (
		SHOOTING_PLANT_SCENE.instantiate()
	)

	####################################################
	# DETERMINISTIC NAME
	####################################################

	plant.name = data["name"]

	####################################################
	# DIRECTION
	####################################################

	var direction = data["direction"]

	####################################################
	# POSITION
	####################################################

	plant.global_position = (
		data["position"]
		- (direction * 20.0)
	)

	####################################################
	# ROTATION
	####################################################

	plant.animation_direction = "up"

	if direction == Vector2.UP:

		plant.rotation_degrees = 0
		plant.bullet_direction = "up"

	elif direction == Vector2.RIGHT:

		plant.rotation_degrees = 90
		plant.bullet_direction = "right"

	elif direction == Vector2.DOWN:

		plant.rotation_degrees = 180
		plant.bullet_direction = "down"

	elif direction == Vector2.LEFT:

		plant.rotation_degrees = -90
		plant.bullet_direction = "left"

	####################################################
	# OWNER
	####################################################

	plant.owner_peer_id = int(
		data["owner_peer_id"]
	)

	####################################################
	# SUBTLE DEPTH
	####################################################

	plant.z_index = -1

	print(
		"Spawned shooting plant for peer:",
		plant.owner_peer_id
	)

	return plant

func spawn_bullet(
	position : Vector2,
	direction : String,
	owner_peer_id : int
):

	if !multiplayer.is_server():
		return

	var bullet_name = (
		"Bullet_"
		+ str(Time.get_ticks_usec())
	)

	bullet_spawner.spawn({
		"name": bullet_name,
		"position": position,
		"direction": direction,
		"owner_peer_id": owner_peer_id
	})

func spawn_network_bullet(data):

	var bullet = (
		BULLET_SCENE.instantiate()
	)

	bullet.name = data["name"]

	bullet.global_position = (
		data["position"]
	)

	bullet.call_deferred(
		"set_direction",
		data["direction"]
	)

	bullet.owner_peer_id = int(
		data["owner_peer_id"]
	)

	return bullet


func start_match_timer():

	while match_time_left > 0:

		await get_tree().create_timer(
			1.0
		).timeout
		
		match_time_left -= 1
		print("Time left:", match_time_left)
		NetworkManager.sync_match_time.rpc(
			match_time_left
		)

	end_match()


func end_match():

	print("Match ended")
	
	match_finished = true
	
	####################################################
	# FIND WINNER
	####################################################

	var best_peer_id := -1

	var best_score := -999999
	
	match_finished = true
	
	
	for peer_id in (
		NetworkManager.player_kills
	):

		var kills = (
			NetworkManager.player_kills[
				peer_id
			]
		)

		if kills > best_score:

			best_score = kills

			best_peer_id = peer_id

	####################################################
	# WINNER NAME
	####################################################

	var winner_name = (
		NetworkManager.player_usernames.get(
			best_peer_id,
			"Player"
		)
	)

	print("Winner:", winner_name)

	####################################################
	# SHOW MATCH END FOR EVERYONE
	####################################################

	NetworkManager.end_match_rpc.rpc(
		winner_name
	)
	
	

	####################################################
	# WAIT 10 SECONDS
	####################################################

	await get_tree().create_timer(
		10.0
	).timeout

	####################################################
	# CLOSE CONNECTION
	####################################################

	if multiplayer.multiplayer_peer:

		multiplayer.multiplayer_peer.close()

	####################################################
	# RETURN TO MENU
	####################################################

	get_tree().change_scene_to_file(
		"res://scenes/Main_Menu.tscn"
	)
