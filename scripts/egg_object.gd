extends RigidBody2D

class_name EggObject


###########
# SIGNALS
###########

signal egg_broken
signal egg_landed


###########
# EGG DATA
###########

@export var egg_data : EggData


###########
# SETTINGS
###########

#@export var break_velocity_threshold := 250.0


###########
# STATE
###########

var owner_peer_id := -1

var used := false
var landed := false
var broke := false

var pickup_blocked := false

var world_spawned := false

var last_velocity := Vector2.ZERO

var collision_direction := Vector2.UP

###########
# NODES
###########

@onready var sprite = $Sprite2D
@onready var pickup_area = $PickupArea


###########
# READY
###########

func _ready():

	###########
	# PHYSICS SETUP
	###########

	contact_monitor = true

	max_contacts_reported = 8

	body_shape_entered.connect(
		_on_body_entered
	)

	pickup_area.area_entered.connect(
		_on_pickup_area_entered
	)

	###########
	# VISUALS
	###########

	if egg_data and egg_data.icon:

		sprite.texture = egg_data.icon


###########
# PHYSICS
###########

func _physics_process(delta):

	###########
	# ONLY SERVER SIMULATES EGG PHYSICS
	###########

	if multiplayer.has_multiplayer_peer():

		if !multiplayer.is_server():
			return

	last_velocity = linear_velocity

func _integrate_forces(state):

	if state.get_contact_count() == 0:
		return

	###########
	# GET REAL COLLISION NORMAL
	###########

	var normal = state.get_contact_local_normal(0)

	###########
	# SNAP TO CARDINAL DIRECTION
	###########

	if abs(normal.x) > abs(normal.y):

		collision_direction = (
			Vector2.RIGHT
			* sign(normal.x)
		)

	else:

		collision_direction = (
			Vector2.DOWN
			* sign(normal.y)
		)

###########
# PICKUP
###########

func _on_pickup_area_entered(area):

	###########
	# ONLY SERVER HANDLES PICKUP
	###########

	if !multiplayer.is_server():
		return

	###########
	# SAFETY
	###########

	if pickup_blocked:
		return

	if used:
		return

	if area.name != "Hurtbox":
		return

	###########
	# GET PLAYER FROM HURTBOX
	###########

	var player = area.get_parent()

	if player == null:
		return

	###########
	# FIND REAL AUTHORITATIVE PLAYER
	###########

	var peer_id = (
		player.get_multiplayer_authority()
	)

	var level = (
		get_tree()
		.get_first_node_in_group("level")
	)

	if level == null:
		return

	var real_player = (
		level.players.get_node_or_null(
			str(peer_id)
		)
	)

	if real_player == null:
		return

	###########
	# VALIDATE INVENTORY
	###########

	if !real_player.has_method("add_egg"):
		return

	###########
	# TRY ADDING EGG
	###########

	var success = (
		real_player.add_egg(egg_data)
	)

	if !success:
		return
	
	###########
	# RESTORE PHYSICS
	###########

	set_deferred("freeze", false)

	world_spawned = false

	###########
	# MARK USED
	###########
	if egg_data.egg_name == "Respawn Egg":
		used = true

	###########
	# DEBUG
	###########

	print(
		real_player.username,
		" picked up ",
		egg_data.egg_name
	)

	###########
	# SPAWNER SYNCS DELETION
	###########

	queue_free()

###########
# LAND / BREAK
###########

func _on_body_entered(
	_rid,
	_body,
	_body_shape,
	_local_shape
):

	###########
	# ONLY SERVER DECIDES COLLISIONS
	###########

	if !multiplayer.is_server():
		return

	###########
	# PREVENT DOUBLE PROCESSING
	###########

	if landed or broke:
		return

	###########
	# IMPACT STRENGTH
	###########

	var impact = last_velocity.length()

	###########
	# COLLISION DIRECTION
	###########

	var direction = -collision_direction

	###########
	# BREAK
	###########
	print(
		"Impact:",
		impact,
		" Threshold:",
		egg_data.break_velocity_threshold
	)
	if impact > egg_data.break_velocity_threshold:

		broke = true

		call_deferred(
			"break_egg",
			direction
		)

	###########
	# LAND
	###########

	else:

		landed = true

		call_deferred("land_egg")

###########
# LAND EGG
###########

func land_egg():

	if egg_data == null:
		return

	print(
		egg_data.egg_name,
		" landed safely"
	)

	###########
	# FREEZE PHYSICS
	###########

	freeze = true

	sleeping = true

	emit_signal("egg_landed", self)

	###########
	# LANDED EFFECT
	###########

	if egg_data.landed_effect_scene:

		var effect = (
			egg_data
			.landed_effect_scene
			.instantiate()
		)

		get_tree().current_scene.add_child(effect)

		effect.activate(self, Vector2.ZERO)


###########
# BREAK EGG
###########

func break_egg(hit_direction):

	if used:
		return

	if egg_data == null:
		return

	used = true

	print(
		egg_data.egg_name,
		" broke"
	)

	emit_signal("egg_broken", self)

	###########
	# BREAK EFFECT
	###########

	if egg_data.effect_scene:

		var effect = (
			egg_data
			.effect_scene
			.instantiate()
		)

		get_tree().current_scene.add_child(effect)

		###########
		# PASS SURFACE DIRECTION
		###########

		###########
		# SNAP TO CARDINAL DIRECTION
		###########

		var direction = -hit_direction

		if abs(direction.x) > abs(direction.y):

			direction = Vector2.RIGHT * sign(direction.x)

		else:

			direction = Vector2.DOWN * sign(direction.y)

		effect.activate(
			self,
			direction
		)

	###########
	# SPAWNER SYNCS DELETION
	###########

	queue_free()

func unblock_pickup():

	pickup_blocked = false
