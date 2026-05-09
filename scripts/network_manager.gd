extends Node

const PORT = 9999

var peer = ENetMultiplayerPeer.new()


func host_game():

	var error = peer.create_server(PORT)

	if error != OK:
		print("Failed to host game")
		return

	multiplayer.multiplayer_peer = peer

	print("Server created")


func join_game(ip):

	var error = peer.create_client(ip, PORT)

	if error != OK:
		print("Failed to join game")
		return

	multiplayer.multiplayer_peer = peer

	print("Connected to server")
