extends Node2D

const PLAYER_SCENE = preload(
	"res://scenes/multiplayer_player.tscn"
)

@onready var players = $Players
@onready var spawn_points = $SpawnPoints


####################################################
# READY
####################################################

func _ready():

	add_to_group("level")

	# Host spawns immediately
	if multiplayer.is_server():

		spawn_player(
			multiplayer.get_unique_id()
		)


####################################################
# PLAYER SPAWNING
####################################################

func spawn_player(peer_id):

	# Prevent duplicate players
	if players.has_node(str(peer_id)):
		return

	var player = PLAYER_SCENE.instantiate()

	####################################################
	# PLAYER SETUP
	####################################################

	# Peer ID becomes node name
	player.name = str(peer_id)

	# Username from NetworkManager
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
