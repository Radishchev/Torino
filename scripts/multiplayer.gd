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


####################################################
# TEST EGG DATA
####################################################

const HEAL_EGG = preload(
	"res://scenes/eggs/resources/heal_egg.tres"
)

const SPIKE_EGG = preload(
	"res://scenes/eggs/resources/spike_egg.tres"
)



####################################################
# NODES
####################################################

@onready var players = $Players
@onready var spawn_points = $SpawnPoints

@onready var eggs = $Eggs
@onready var egg_spawns = $EggSpawns
@onready var egg_spawner = $EggSpawner

@onready var spike_spawner = $SpikeSpawner

####################################################
# READY
####################################################

func _ready():

	add_to_group("level")

	####################################################
	# IMPORTANT
	# MultiplayerSpawner setup
	####################################################

	egg_spawner.spawn_function = spawn_network_egg
	
	spike_spawner.spawn_function = spawn_network_spike

	####################################################
	# HOST STARTUP
	####################################################

	if multiplayer.is_server():

		spawn_player(
			multiplayer.get_unique_id()
		)

		spawn_starting_eggs()


####################################################
# PLAYER SPAWNING
####################################################

func spawn_player(peer_id):

	####################################################
	# PREVENT DUPLICATES
	####################################################

	if players.has_node(str(peer_id)):
		return

	var player = PLAYER_SCENE.instantiate()

	####################################################
	# PLAYER SETUP
	####################################################

	player.name = str(peer_id)

	player.username = (
		NetworkManager
		.player_usernames
		.get(peer_id, "Player")
	)

	####################################################
	# ADD PLAYER
	####################################################

	players.add_child(player, true)

	####################################################
	# SPAWN POSITION
	####################################################

	var spawn_index = (
		players.get_child_count() - 1
	)

	spawn_index = clamp(
		spawn_index,
		0,
		spawn_points.get_child_count() - 1
	)

	player.global_position = (
		spawn_points
		.get_child(spawn_index)
		.global_position
	)

	####################################################
	# DEBUG
	####################################################

	print(
		"Spawned player:",
		peer_id,
		" username:",
		player.username,
		" at ",
		player.global_position
	)


####################################################
# STARTING EGGS
####################################################

func spawn_starting_eggs():

	for spawn in egg_spawns.get_children():

		spawn_egg(
			SPIKE_EGG,
			spawn.global_position
		)


####################################################
# NETWORK EGG SPAWNING
####################################################

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
