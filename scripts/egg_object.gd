extends RigidBody2D

class_name EggObject


signal egg_broken
signal egg_landed


@export var egg_data : EggData

@export var break_velocity_threshold := 250.0


var owner_peer_id := -1

var used := false
var landed := false
var broke := false

var last_velocity := Vector2.ZERO


@onready var sprite = $Sprite2D
@onready var pickup_area = $PickupArea


func _ready():

	contact_monitor = true
	max_contacts_reported = 8

	body_shape_entered.connect(
		_on_body_entered
	)

	pickup_area.area_entered.connect(
		_on_pickup_area_entered
	)

	# Set egg sprite from EggData
	if egg_data and egg_data.icon:

		sprite.texture = egg_data.icon


func _physics_process(delta):

	last_velocity = linear_velocity


###############################################################
# PICKUP
###############################################################

func _on_pickup_area_entered(area):
	
	print("Pickup touched:", area.name)
	
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

	if landed or broke:
		return

	var impact = abs(last_velocity.y)

	if impact > break_velocity_threshold:

		broke = true

		call_deferred("break_egg")

	else:

		landed = true

		call_deferred("land_egg")


func land_egg():

	print(
		egg_data.egg_name,
		" landed safely"
	)

	freeze = true
	sleeping = true

	emit_signal("egg_landed", self)

	# Trigger landed effect
	if egg_data and egg_data.landed_effect_scene:

		var effect = (
			egg_data.landed_effect_scene.instantiate()
		)

		get_tree().current_scene.add_child(effect)

		effect.activate(self)


func break_egg():

	if used:
		return

	used = true

	print(
		egg_data.egg_name,
		" broke"
	)

	emit_signal("egg_broken", self)

	# Trigger break effect
	if egg_data and egg_data.effect_scene:

		var effect = (
			egg_data.effect_scene.instantiate()
		)

		get_tree().current_scene.add_child(effect)

		effect.activate(self)

	queue_free()
