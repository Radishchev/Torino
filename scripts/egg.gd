extends RigidBody2D

var used := false
signal egg_broken
signal egg_landed

@export var break_velocity_threshold: float = 250.0

@onready var shape: CollisionShape2D = $CollisionShape2D

var last_velocity := Vector2.ZERO

# These MUST exist so the Player can assign them
var was_finalized := false   # true once the egg has landed or broken
var broke := false           # true if egg broke on landing


func _ready():
	contact_monitor = true
	max_contacts_reported = 8
	freeze = false

	connect("body_shape_entered", _on_body_entered)


func _physics_process(_delta):
	last_velocity = linear_velocity


func _on_body_entered(_rid, _body, _body_shape, _local_shape):
	if was_finalized:
		return

	was_finalized = true

	var impact_speed = abs(last_velocity.y)
	print("Egg impact:", impact_speed)

	if impact_speed > break_velocity_threshold:
		broke = true
		break_egg()
	else:
		broke = false
		land_egg()


func land_egg():
	if used:
		return

	print("✨ Egg survived landing")

	# Freeze in place
	freeze = true
	freeze_mode = RigidBody2D.FREEZE_MODE_KINEMATIC
	sleeping = true
	linear_velocity = Vector2.ZERO
	angular_velocity = 0

	emit_signal("egg_landed", self)


func mark_as_checkpoint():
	if not used:
		modulate = Color(1, 1, 0.5)


func break_egg():
	if used:
		return

	used = true
	print("💥 Egg breaking...")

	if shape:
		shape.disabled = true

	collision_layer = 0
	collision_mask = 0

	# Freeze physics
	freeze = true
	freeze_mode = RigidBody2D.FREEZE_MODE_KINEMATIC
	sleeping = true

	modulate = Color(0.6, 0.6, 0.6, 0.5)

	emit_signal("egg_broken", self)

	call_deferred("queue_free")
