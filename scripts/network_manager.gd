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

var player_kills := {}

func add_kill(peer_id):

	if !multiplayer.is_server():
		return

	if !player_kills.has(peer_id):
		player_kills[peer_id] = 0

	player_kills[peer_id] += 1

	print(
		"Kill added to:",
		peer_id,
		" total:",
		player_kills[peer_id]
	)

	broadcast_leaderboard()

@rpc("any_peer", "call_local")
func request_add_kill(peer_id):

	if !multiplayer.is_server():
		return

	add_kill(peer_id)
	
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
	
	player_kills[multiplayer.get_unique_id()] = 0
	
	broadcast_leaderboard()

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
	
	if !player_kills.has(sender_id):

		player_kills[sender_id] = 0
		
		broadcast_leaderboard()

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


func broadcast_leaderboard():

	if !multiplayer.is_server():
		return

	####################################################
	# UPDATE SERVER LOCALLY
	####################################################

	sync_leaderboard_data(
		player_usernames,
		player_kills
	)

	####################################################
	# UPDATE CLIENTS
	####################################################

	sync_leaderboard_data.rpc(
		player_usernames,
		player_kills
	)
	

@rpc("authority", "call_local")
func sync_leaderboard_data(
	usernames : Dictionary,
	kills : Dictionary
):

	player_usernames = usernames

	player_kills = kills

	print("Leaderboard synced")

	####################################################
	# UPDATE HUD
	####################################################

	var hud = (
		get_tree()
		.get_first_node_in_group("hud")
	)

	if hud:

		hud.update_leaderboard()
