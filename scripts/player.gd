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

func _ready() -> void:
	spawn_point = global_position


func _physics_process(delta: float) -> void:
	# Apply gravity
	velocity.y += gravity * delta

	# Horizontal movement (momentum based)
	var direction = Input.get_axis("move_left", "move_right")

	if direction != 0:
		drifting = false
		velocity.x += direction * move_acceleration * delta
		velocity.x = clamp(velocity.x, -max_speed, max_speed)
	else:
		drifting = true
		velocity.x = lerp(velocity.x, 0.0, drift_friction)

	# Flap
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


func drop_egg():
	if egg_scene:
		var egg = egg_scene.instantiate()
		get_parent().add_child(egg)
		# Drop slightly below the bird
		egg.global_position = global_position + Vector2(0, 16)


func die() -> void:
	print("Bird crashed!")
	global_position = spawn_point
	velocity = Vector2.ZERO
