extends RigidBody2D

var used := false
signal egg_broken

@onready var shape: CollisionShape2D = $CollisionShape2D

func _ready():
	freeze = false

func mark_as_checkpoint():
	if not used:
		modulate = Color(1, 1, 0.5)

func break_egg():
	if used:
		return
	used = true
	print("💥 Breaking egg...")

	# --- Disable all collisions right now ---
	if shape:
		shape.disabled = true
	collision_layer = 0
	collision_mask = 0

	# --- Stop all physics motion ---
	freeze = true
	freeze_mode = RigidBody2D.FREEZE_MODE_KINEMATIC
	sleeping = true

	# --- Optional tint to look broken ---
	modulate = Color(0.6, 0.6, 0.6, 0.5)

	emit_signal("egg_broken")

	# --- Remove completely ---
	queue_free()
