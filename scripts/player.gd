extends CharacterBody2D

# --- Movement Settings ---
@export var gravity: float = 800.0
@export var flap_strength: float = -250.0
@export var move_acceleration: float = 180.0
@export var max_speed: float = 180.0
@export var drift_friction: float = 0.1
@export var crash_speed: float = 450.0

# --- Egg Drop ---
@export var egg_scene: PackedScene

# --- Animation ---
@export var idle_anim_name := "idle"
@export var fly_anim_name := "flying"
const GROUNDED_GRACE := 0.08        # seconds to prevent flicker
const VY_THRESHOLD := 20.0          # small vertical motion still counts as grounded
var air_time := 0.0

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

var spawn_point: Vector2
var drifting: bool = false
var egg_stack: Array = []  # stores up to 3 eggs (latest at end)

func _ready() -> void:
	spawn_point = global_position
	# start correct anim based on initial state
	if is_on_floor():
		anim.play(idle_anim_name)
	else:
		anim.play(fly_anim_name)

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

	# --- Animation state update ---
	# Track time in air with a small grace to avoid flicker on slopes/bumps.
	if is_on_floor() and abs(velocity.y) <= VY_THRESHOLD:
		air_time = 0.0
	else:
		air_time += delta

	var should_fly := air_time > GROUNDED_GRACE or Input.is_action_pressed("flap")

	if should_fly:
		if anim.animation != fly_anim_name:
			anim.play(fly_anim_name)
	else:
		if anim.animation != idle_anim_name:
			anim.play(idle_anim_name)

	# Optional: make flying anim flap faster when moving faster vertically.
	# (Safe ranges—tweak if you like.)
	var speed_scale: float = clamp(remap(abs(velocity.y), 0.0, 400.0, 0.7, 1.6), 0.7, 1.6)

	anim.speed_scale = speed_scale if anim.animation == fly_anim_name else 1.0

	# --- Facing ---
	if direction > 0:
		anim.flip_h = true
	elif direction < 0:
		anim.flip_h = false

	if abs(velocity.x) > crash_speed:
		die()

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
	egg_stack.append(egg)
	spawn_point = egg.global_position
	if egg.has_method("mark_as_checkpoint"):
		egg.mark_as_checkpoint()
	print("🥚 Egg dropped! Total eggs:", egg_stack.size())

func die() -> void:
	print("💀 Bird crashed!")
	if egg_stack.size() > 0:
		var last_egg = egg_stack.pop_back()
		if last_egg.has_signal("egg_broken"):
			last_egg.egg_broken.connect(_on_egg_broken.bind(last_egg))
			last_egg.break_egg()
		else:
			print("⚠️ Egg has no egg_broken signal; breaking directly.")
			spawn_point = last_egg.global_position
			last_egg.queue_free()
			global_position = spawn_point
			velocity = Vector2.ZERO
	else:
		print("🚨 No eggs left! Restarting level.")
		get_tree().reload_current_scene()

func _on_egg_broken(egg):
	spawn_point = egg.global_position
	global_position = spawn_point
	velocity = Vector2.ZERO
	print("🕊️ Respawned. Eggs left:", egg_stack.size())
