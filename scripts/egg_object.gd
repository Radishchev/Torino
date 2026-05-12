extends RigidBody2D

class_name EggObject


###############################################################
# SIGNALS
###############################################################

signal egg_broken
signal egg_landed


###############################################################
# EGG DATA
###############################################################

@export var egg_data : EggData


###############################################################
# SETTINGS
###############################################################

@export var break_velocity_threshold := 250.0


###############################################################
# STATE
###############################################################

var owner_peer_id := -1

var used := false
var landed := false
var broke := false

var pickup_blocked := false

var last_velocity := Vector2.ZERO


###############################################################
# NODES
###############################################################

@onready var sprite = $Sprite2D
@onready var pickup_area = $PickupArea


###############################################################
# READY
###############################################################

func _ready():

	###############################################################
	# PHYSICS SETUP
	###############################################################

	contact_monitor = true

	max_contacts_reported = 8

	body_shape_entered.connect(
		_on_body_entered
	)

	pickup_area.area_entered.connect(
		_on_pickup_area_entered
	)

	###############################################################
	# VISUALS
	###############################################################

	# Set sprite from EggData
	if egg_data and egg_data.icon:

		sprite.texture = egg_data.icon


###############################################################
# PHYSICS
###############################################################

func _physics_process(delta):

	last_velocity = linear_velocity


###############################################################
# PICKUP
###############################################################

func _on_pickup_area_entered(area):

	# Temporary throw protection
	if pickup_blocked:
		return

	# Already used
	if used:
		return

	# Only detect player hurtboxes
	if area.name != "Hurtbox":
		return

	var player = area.get_parent()

	# Safety check
	if !player.has_method("add_egg"):
		return

	# Try adding egg to inventory
	var success = player.add_egg(egg_data)

	if success:

		print(
			player.username,
			" picked up ",
			egg_data.egg_name
		)

		queue_free()


###############################################################
# LAND / BREAK
###############################################################

func _on_body_entered(
	_rid,
	_body,
	_body_shape,
	_local_shape
):

	# Prevent double processing
	if landed or broke:
		return

	var impact = abs(last_velocity.y)

	###############################################################
	# BREAK
	###############################################################

	if impact > break_velocity_threshold:

		broke = true

		call_deferred("break_egg")

	###############################################################
	# LAND
	###############################################################

	else:

		landed = true

		call_deferred("land_egg")


###############################################################
# LAND EGG
###############################################################

func land_egg():

	if egg_data == null:
		return

	print(
		egg_data.egg_name,
		" landed safely"
	)

	# Freeze physics
	freeze = true

	sleeping = true

	emit_signal("egg_landed", self)

	###############################################################
	# LANDED EFFECT
	###############################################################

	if egg_data.landed_effect_scene:

		var effect = (
			egg_data
			.landed_effect_scene
			.instantiate()
		)

		get_tree().current_scene.add_child(effect)

		effect.activate(self)


###############################################################
# BREAK EGG
###############################################################

func break_egg():

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

	###############################################################
	# BREAK EFFECT
	###############################################################

	if egg_data.effect_scene:

		var effect = (
			egg_data
			.effect_scene
			.instantiate()
		)

		get_tree().current_scene.add_child(effect)

		effect.activate(self)

	queue_free()
