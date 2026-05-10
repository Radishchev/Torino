extends Node

const PORT = 9999

var peer = ENetMultiplayerPeer.new()

# LOCAL PLAYER DATA
var player_username := ""

# SERVER STORED USERNAMES
# peer_id -> username
var player_usernames := {}


# RANDOM USERNAME PARTS
var random_first = [
	"Bubble",
	"Rocket",
	"Fluffy",
	"Toasty",
	"Chirpy",
	"Wobble",
	"Snappy",
	"Fuzzy",
	"Zippy",
	"Nugget"
]

var random_second = [
	"Wing",
	"Feather",
	"Bird",
	"Egg",
	"Rocket",
	"Nest",
	"Flap",
	"Cloud",
	"Bounce",
	"Spark"
]


func generate_random_username():

	return (
		random_first.pick_random()
		+ random_second.pick_random()
	)


func host_game():

	var error = peer.create_server(PORT)

	if error != OK:
		print("Failed to host game")
		return

	multiplayer.multiplayer_peer = peer

	# Store host username immediately
	player_usernames[multiplayer.get_unique_id()] = player_username

	print("Server created")


func join_game(ip = "127.0.0.1"):

	var error = peer.create_client(ip, PORT)

	if error != OK:
		print("Failed to join game")
		return

	multiplayer.multiplayer_peer = peer

	print("Connected to server")

	# Wait until fully connected
	await multiplayer.connected_to_server

	# Send username to server
	send_username.rpc_id(1, player_username)


@rpc("any_peer")
func send_username(username):

	# Get sender peer ID
	var sender_id = multiplayer.get_remote_sender_id()

	# Store username on server
	player_usernames[sender_id] = username

	print(
		"Received username from ",
		sender_id,
		": ",
		username
	)

	# Only server should spawn players
	if multiplayer.is_server():

		var level = get_tree().get_first_node_in_group("level")

		if level:
			level.spawn_player(sender_id)
