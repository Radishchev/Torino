extends RigidBody2D

var used := false
signal egg_broken
signal egg_landed

@export var break_velocity_threshold: float = 250.0

@onready var shape: CollisionShape2D = $CollisionShape2D

var last_velocity := Vector2.ZERO

var was_finalized := false
var broke := false


func _ready():
	contact_monitor = true
	max_contacts_reported = 8
	freeze = false

	# Godot 4: body_shape_entered is OK but must not mutate inside callback
	connect("body_shape_entered", _on_body_entered)


func _physics_process(_delta):
	last_velocity = linear_velocity


func _on_body_entered(_rid, _body, _body_shape, _local_shape):
	if was_finalized:
		return

	was_finalized = true

	var impact = abs(last_velocity.y)
	print("Egg impact:", impact)

	if impact > break_velocity_threshold:
		broke = true
		call_deferred("break_egg_safe")
	else:
		broke = false
		call_deferred("land_egg_safe")


###############################################################
### SAFE LAND LOGIC (executed deferred)
###############################################################

func land_egg_safe():
	if used:
		return

	print("✨ Egg survived landing")

	# Freeze safely
	freeze = true
	freeze_mode = RigidBody2D.FREEZE_MODE_KINEMATIC
	sleeping = true
	linear_velocity = Vector2.ZERO
	angular_velocity = 0

	emit_signal("egg_landed", self)


###############################################################
### SAFE BREAK LOGIC (executed deferred)
###############################################################

func break_egg_safe():
	if used:
		return

	used = true
	print("💥 Egg breaking...")

	if shape:
		shape.call_deferred("set_disabled", true)

	# Disable collisions safely
	set_deferred("collision_layer", 0)
	set_deferred("collision_mask", 0)

	# Freeze body safely
	set_deferred("freeze", true)
	set_deferred("freeze_mode", RigidBody2D.FREEZE_MODE_KINEMATIC)
	set_deferred("sleeping", true)

	modulate = Color(0.6, 0.6, 0.6, 0.5)

	emit_signal("egg_broken", self)

	# Destroy safely
	call_deferred("queue_free")


###############################################################
### Optional: Visual indicator when used
###############################################################

func mark_as_checkpoint():
	if not used:
		modulate = Color(1, 1, 0.5)
