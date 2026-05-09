extends Node2D

const PLAYER_SCENE = preload(
	"res://scenes/multiplayer_player.tscn"
)

@onready var players = $Players
@onready var spawn_points = $SpawnPoints


func _ready():

	multiplayer.peer_connected.connect(
		_on_peer_connected
	)

	# Host spawns itself
	if multiplayer.is_server():

		spawn_player(
			multiplayer.get_unique_id()
		)


func _on_peer_connected(id):

	if multiplayer.is_server():

		spawn_player(id)


func spawn_player(peer_id):

	if players.has_node(str(peer_id)):
		return

	var player = PLAYER_SCENE.instantiate()

	player.name = str(peer_id)

	# Use player order instead of peer ID
	var spawn_index = players.get_child_count()

	spawn_index = clamp(
		spawn_index,
		0,
		spawn_points.get_child_count() - 1
	)

	player.global_position = spawn_points.get_child(
		spawn_index
	).global_position

	players.add_child(player, true)

	print(
		"Spawned player:",
		peer_id,
		" at ",
		player.global_position
	)
