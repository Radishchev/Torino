extends Node

signal lan_games_updated

const PORT = 9999
const DISCOVERY_PORT = 9998

var peer = ENetMultiplayerPeer.new()

####################################################
# LAN DISCOVERY
####################################################

var udp_server := PacketPeerUDP.new()
var udp_listener := PacketPeerUDP.new()

var discovered_games := {}
var discovery_running := false

####################################################
# LOCAL PLAYER DATA
####################################################

var player_username := ""

####################################################
# SERVER STORED USERNAMES
####################################################

var lobby_players := {}
var player_usernames := {}

####################################################
# RANDOM USERNAME PARTS
####################################################

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

enum MatchState {
	LOBBY,
	IN_GAME,
	MATCH_END
}

var current_match_state = (
	MatchState.LOBBY
)

var match_duration := 300

var current_match_time := 0

####################################################
# LEADERBOARD
####################################################

var player_kills := {}

####################################################
# READY
####################################################

func _ready():

	setup_disconnect_handler()

	multiplayer.peer_disconnected.connect(
		_on_peer_disconnected
	)


@rpc("authority", "call_local")
func sync_match_time(time_left):

	current_match_time = time_left
	
	
####################################################
# KILLS
####################################################

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

func remove_kill(peer_id):

	if !multiplayer.is_server():
		return

	if !player_kills.has(peer_id):
		player_kills[peer_id] = 0

	player_kills[peer_id] = max(
		player_kills[peer_id] - 1,
		0
	)

	print(
		"Kill removed from:",
		peer_id,
		" total:",
		player_kills[peer_id]
	)

	broadcast_leaderboard()

@rpc("any_peer", "call_local")
func request_remove_kill(peer_id):

	if !multiplayer.is_server():
		return

	remove_kill(peer_id)

####################################################
# USERNAME
####################################################

func generate_random_username():

	return (
		random_first.pick_random()
		+ random_second.pick_random()
	)

####################################################
# HOST GAME
####################################################

func host_game():

	####################################################
	# RESET PEER
	####################################################

	peer = ENetMultiplayerPeer.new()

	var error = peer.create_server(PORT)

	if error != OK:

		print("Failed to host game")
		return

	multiplayer.multiplayer_peer = peer

	####################################################
	# STORE HOST
	####################################################

	var host_id = (
		multiplayer.get_unique_id()
	)

	player_usernames[host_id] = (
		player_username
	)

	lobby_players[host_id] = (
		player_username
	)

	player_kills[host_id] = 0

	####################################################
	# SYNC
	####################################################

	broadcast_leaderboard()
	broadcast_lobby()

	print("Server created")

	####################################################
	# LAN BROADCAST
	####################################################

	start_lan_broadcast()

####################################################
# JOIN GAME
####################################################

func join_game(ip = "127.0.0.1"):

	####################################################
	# RESET PEER
	####################################################

	peer = ENetMultiplayerPeer.new()

	var error = peer.create_client(
		ip,
		PORT
	)

	if error != OK:

		print("Failed to join game")
		return

	multiplayer.multiplayer_peer = peer

	print("Connected to server")

	await multiplayer.connected_to_server

	send_username.rpc_id(
		1,
		player_username
	)

####################################################
# LAN BROADCAST
####################################################

func start_lan_broadcast():

	udp_server.set_broadcast_enabled(true)

	while (
		multiplayer.multiplayer_peer != null
		and multiplayer.is_server()
	):

		####################################################
		# VALID PEER
		####################################################

		var current_peer = (
			multiplayer.multiplayer_peer
		)

		if current_peer == null:
			break

		####################################################
		# MUST STILL BE HOST
		####################################################

		if current_peer != peer:
			break

		####################################################
		# SEND BROADCAST
		####################################################

		var message = JSON.stringify({
			"name": player_username,
			"port": PORT
		})

		udp_server.set_dest_address(
			"255.255.255.255",
			DISCOVERY_PORT
		)

		udp_server.put_packet(
			message.to_utf8_buffer()
		)

		await get_tree().create_timer(
			1.0
		).timeout

	print("Stopped LAN broadcast")

####################################################
# LAN DISCOVERY
####################################################

func start_lan_discovery():

	if discovery_running:
		return

	discovery_running = true

	####################################################
	# CLEAN OLD LISTENER
	####################################################

	udp_listener.close()

	discovered_games.clear()

	var error = udp_listener.bind(
		DISCOVERY_PORT
	)

	if error != OK:

		print(
			"Failed to bind discovery port"
		)

		return

	print("Listening for LAN games")

	while true:

		await get_tree().process_frame

		while (
			udp_listener
			.get_available_packet_count()
			> 0
		):

			var packet = (
				udp_listener.get_packet()
			)

			var ip = (
				udp_listener.get_packet_ip()
			)

			var data = JSON.parse_string(
				packet.get_string_from_utf8()
			)

			if data == null:
				continue

			discovered_games[ip] = data

			lan_games_updated.emit()

####################################################
# USERNAME SYNC
####################################################

@rpc("any_peer")
func send_username(username):

	var sender_id = (
		multiplayer.get_remote_sender_id()
	)

	player_usernames[sender_id] = username

	lobby_players[sender_id] = username

	if !player_kills.has(sender_id):

		player_kills[sender_id] = 0

	broadcast_leaderboard()
	broadcast_lobby()

	print(
		"Received username from ",
		sender_id,
		": ",
		username
	)

####################################################
# LEADERBOARD
####################################################

func broadcast_leaderboard():

	if multiplayer.multiplayer_peer == null:
		return

	if !multiplayer.is_server():
		return

	sync_leaderboard_data(
		player_usernames,
		player_kills
	)

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

	var hud = (
		get_tree()
		.get_first_node_in_group("hud")
	)

	if hud:

		hud.update_leaderboard()

####################################################
# LOBBY
####################################################

@rpc("authority", "call_local")
func sync_lobby_players(players : Dictionary):

	lobby_players = players

	print(
		"Lobby synced:",
		lobby_players
	)

func broadcast_lobby():

	if multiplayer.multiplayer_peer == null:
		return

	if !multiplayer.is_server():
		return

	sync_lobby_players(
		lobby_players
	)

	sync_lobby_players.rpc(
		lobby_players
	)

####################################################
# START MATCH
####################################################

@rpc("authority", "call_local")
func start_match():

	get_tree().change_scene_to_file(
		"res://scenes/multiplayer.tscn"
	)

####################################################
# DISCONNECT HANDLING
####################################################

func setup_disconnect_handler():

	multiplayer.server_disconnected.connect(
		_on_server_disconnected
	)

func _on_server_disconnected():

	print("Disconnected from host")

	####################################################
	# CLEAN MULTIPLAYER
	####################################################

	if multiplayer.multiplayer_peer:

		multiplayer.multiplayer_peer.close()

	multiplayer.multiplayer_peer = null

	####################################################
	# CLEAR DATA
	####################################################

	lobby_players.clear()
	player_usernames.clear()
	player_kills.clear()
	discovered_games.clear()

	####################################################
	# RETURN TO MENU
	####################################################

	get_tree().change_scene_to_file(
		"res://scenes/multiplayer_menu.tscn"
	)

func _on_peer_disconnected(peer_id):

	print(
		"Peer disconnected:",
		peer_id
	)

	####################################################
	# REMOVE DATA
	####################################################

	lobby_players.erase(peer_id)

	player_usernames.erase(peer_id)

	player_kills.erase(peer_id)

	####################################################
	# SYNC
	####################################################

	broadcast_lobby()
	broadcast_leaderboard()

	####################################################
	# REMOVE PLAYER NODE
	####################################################

	var level = (
		get_tree()
		.get_first_node_in_group("level")
	)

	if level:

		var player = (
			level.players.get_node_or_null(
				str(peer_id)
			)
		)

		if player:

			player.queue_free()


@rpc("authority", "call_local")
func end_match_rpc(winner_name):

	var hud = (
		get_tree()
		.get_first_node_in_group("hud")
	)

	if hud:

		hud.show_match_finished(
			winner_name
		)


@rpc("authority", "call_local")
func sync_match_state(state):

	current_match_state = state
