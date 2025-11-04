extends CharacterBody2D

# --- Movement Settings ---
@export var gravity: float = 800.0
@export var flap_strength: float = -250.0
@export var move_acceleration: float = 300.0
@export var max_speed: float = 300.0
@export var drift_friction: float = 0.05
@export var crash_speed: float = 450.0

# --- Egg Drop ---
@export var egg_scene: PackedScene

var spawn_point: Vector2
var drifting: bool = false
var egg_stack: Array = []  # stores up to 3 eggs (latest at end)

func _ready() -> void:
	spawn_point = global_position


func _physics_process(delta: float) -> void:
	velocity.y += gravity * delta

	var direction = Input.get_axis("move_left", "move_right")

	if direction != 0:
		drifting = false
		velocity.x += direction * move_acceleration * delta
		velocity.x = clamp(velocity.x, -max_speed, max_speed)
	else:
		drifting = true
		velocity.x = lerp(velocity.x, 0.0, drift_friction)

	if Input.is_action_just_pressed("flap"):
		velocity.y = flap_strength

	move_and_slide()

	if abs(velocity.x) > crash_speed:
		die()

	if direction > 0:
		$AnimatedSprite2D.flip_h = true
	elif direction < 0:
		$AnimatedSprite2D.flip_h = false


func _input(event):
	if Input.is_action_just_pressed("drop_egg"):
		drop_egg()
	
	if Input.is_action_just_pressed("death"):
		die()


func drop_egg():
	if egg_scene == null:
		print("❌ Egg scene not assigned!")
		return

	if egg_stack.size() >= 3:
		print("⚠️ Maximum 3 eggs reached.")
		return

	var egg = egg_scene.instantiate()
	get_parent().add_child(egg)
	egg.global_position = global_position + Vector2(0, 16)

	# Register this egg
	egg_stack.append(egg)
	spawn_point = egg.global_position

	if egg.has_method("mark_as_checkpoint"):
		egg.mark_as_checkpoint()

	print("🥚 Egg dropped! Total eggs:", egg_stack.size())


func die() -> void:
	print("💀 Bird crashed!")

	if egg_stack.size() > 0:
		var last_egg = egg_stack.pop_back()

		# connect once so we respawn only after collision is gone
		if last_egg.has_signal("egg_broken"):
			last_egg.egg_broken.connect(_on_egg_broken.bind(last_egg))
			last_egg.break_egg()
		else:
	# fallback if script not attached (shouldn't normally happen)
			print("⚠️ Egg has no egg_broken signal; breaking directly.")
			spawn_point = last_egg.global_position
			last_egg.queue_free()
			global_position = spawn_point
			velocity = Vector2.ZERO

	else:
		print("🚨 No eggs left! Restarting level.")
		get_tree().reload_current_scene()


func _on_egg_broken(egg):
	# by the time this runs, the egg is already non-colliding
	spawn_point = egg.global_position
	global_position = spawn_point
	velocity = Vector2.ZERO
	print("🕊️ Respawned. Eggs left:", egg_stack.size())
