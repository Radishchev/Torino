extends RigidBody2D

var used := false
signal egg_broken

@onready var shape: CollisionShape2D = $CollisionShape2D


func _ready():
	freeze = false


func mark_as_checkpoint():
	if not used:
		modulate = Color(1, 1, 0.5)  # highlight


func break_egg():
	if used:
		return
	used = true
	print("💥 Egg breaking...")

	# Disable collisions
	if shape:
		shape.disabled = true
	collision_layer = 0
	collision_mask = 0

	# Stop physics
	freeze = true
	freeze_mode = RigidBody2D.FREEZE_MODE_KINEMATIC
	sleeping = true

	# Visual change
	modulate = Color(0.6, 0.6, 0.6, 0.5)

	emit_signal("egg_broken")
	queue_free()
