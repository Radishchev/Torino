extends Area2D

####################################################
# OWNER
####################################################

var owner_peer_id := -1

####################################################
# READY
####################################################

var armed := false


func _ready():

	connect(
		"body_entered",
		_on_body_entered
	)
	
	await get_tree().create_timer(0.15).timeout

	armed = true

####################################################
# DAMAGE
####################################################

func _on_body_entered(body):

	if !multiplayer.is_server():
		return
	if !armed:
		return
		
	if body.has_method("take_damage"):

		var authority = (
			body.get_multiplayer_authority()
		)

		####################################################
		# HOST PLAYER
		####################################################

		if authority == multiplayer.get_unique_id():

			body.call_deferred(
				"take_damage",
				999,
				owner_peer_id
			)

		####################################################
		# REMOTE CLIENT
		####################################################

		else:

			body.take_damage.rpc_id(
				authority,
				999,
				owner_peer_id
			)

		return
