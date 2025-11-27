extends CharacterBody2D

# --- Movement Settings ---
@export var gravity: float = 800.0
@export var flap_strength: float = -250.0
@export var move_acceleration: float = 180.0
@export var max_speed: float = 180.0
@export var drift_friction: float = 0.03
@export var crash_speed: float = 450.0

# --- Egg Checkpoint Settings ---
@export var egg_scene: PackedScene
@export var max_eggs_per_level := 3

var eggs_used := 0
var egg_stack: Array = []

# --- Animation ---
@export var idle_anim_name := "idle"
@export var fly_anim_name := "flying"
const GROUNDED_GRACE := 0.08
const VY_THRESHOLD := 20.0
var air_time := 0.0

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

var spawn_point: Vector2
var drifting := false

var hud: Node = null

# -------- FEATHER COUNT --------
var feather_count := 0


func _ready() -> void:
	spawn_point = global_position
	Globals.register_player(self)

	# Get HUD
	hud = get_tree().current_scene.get_node("HUD")
	hud.update_eggs_remaining(max_eggs_per_level - eggs_used)
	hud.update_feathers_collected(feather_count)

	# Animation setup
	if is_on_floor():
		anim.play(idle_anim_name)
	else:
		anim.play(fly_anim_name)


func _physics_process(delta: float) -> void:
	velocity.y += gravity * delta

	var direction := Input.get_axis("move_left", "move_right")

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

	# --- Animation ---
	if is_on_floor() and abs(velocity.y) <= VY_THRESHOLD:
		air_time = 0.0
	else:
		air_time += delta

	var should_fly := air_time > GROUNDED_GRACE or Input.is_action_pressed("flap")

	if should_fly and anim.animation != fly_anim_name:
		anim.play(fly_anim_name)
	elif not should_fly and anim.animation != idle_anim_name:
		anim.play(idle_anim_name)

	anim.speed_scale = clamp(remap(abs(velocity.y), 0.0, 400.0, 0.7, 1.6), 0.7, 1.6)

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


####################################################
###        FEATHER SIGNAL HANDLER                ###
####################################################

func _on_feather_collected():
	feather_count += 1
	hud.update_feathers_collected(feather_count)
	print("Feathers:", feather_count)


####################################################
###                DROP EGG                      ###
####################################################

func drop_egg():
	if eggs_used >= max_eggs_per_level:
		print("⚠️ No eggs remaining for this level.")
		return

	var egg = egg_scene.instantiate()
	egg.global_position = global_position + Vector2(0, 16)
	get_parent().add_child(egg)

	egg.egg_landed.connect(_on_egg_landed)
	egg.egg_broken.connect(_on_egg_broken)

	egg_stack.append(egg)
	eggs_used += 1

	spawn_point = egg.global_position

	print("🥚 Egg placed:", eggs_used, "/", max_eggs_per_level)

	hud.update_eggs_remaining(max_eggs_per_level - eggs_used)


####################################################
###                DEATH LOGIC                   ###
####################################################

func die() -> void:
	print("💀 Player crashed!")

	if egg_stack.size() > 0:
		var last_egg = egg_stack.back()
		egg_stack.erase(last_egg)

		if last_egg.was_finalized and last_egg.broke:
			respawn_at_spawn_point()
		else:
			spawn_point = last_egg.global_position
			last_egg.call_deferred("queue_free")
			respawn_at_spawn_point()

	else:
		print("🚨 All eggs used — restarting from beginning.")
		get_tree().call_deferred("reload_current_scene")


####################################################
###          EGG SIGNAL HANDLERS                 ###
####################################################

func _on_egg_landed(egg):
	egg.was_finalized = true
	egg.broke = false
	print("✨ Egg survived landing")


func _on_egg_broken(egg):
	egg.was_finalized = true
	egg.broke = true
	print("💥 Egg broke on landing")
	egg_stack.erase(egg)


####################################################
###                RESPAWN LOGIC                 ###
####################################################

func respawn_at_spawn_point():
	global_position = spawn_point
	velocity = Vector2.ZERO


# fallback remap implementation
func remap(value, in_min, in_max, out_min, out_max) -> float:
	return lerp(out_min, out_max, (value - in_min) / (in_max - in_min))


func _on_room_detector_area_entered(area: Area2D) -> void:
	var collision_shape: CollisionShape2D = area.get_node("CollisionShape2D")

	var rect = collision_shape.shape.extents * 2.0
	var size = rect

	# The center of the room area:
	var center := area.global_position

	Globals.change_room(center, size)
