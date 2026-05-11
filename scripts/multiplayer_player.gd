extends CharacterBody2D


####################################################
# MOVEMENT
####################################################

@export var gravity := 900.0
@export var flap_force := -300.0

@export var move_acceleration := 180.0
@export var max_speed := 180.0
@export var drift_friction := 0.03


####################################################
# ANIMATION
####################################################

@export var idle_anim_name := "idle"
@export var fly_anim_name := "flying"

@export var facing_right := true

@export var current_anim := "idle"

const GROUNDED_GRACE := 0.08
const VY_THRESHOLD := 20.0

var air_time := 0.0


####################################################
# NODES
####################################################

@onready var camera = $Camera2D
@onready var username_label = $UsernameLabel
@onready var health_bar = $HealthBar
@onready var attack_area = $AttackArea
@onready var anim = $AnimatedSprite2D


####################################################
# INVENTORY
####################################################
@export var egg_object_scene : PackedScene

var egg_stack : Array[EggData] = []

const MAX_EGGS := 3


####################################################
# USERNAME
####################################################

@export var username := "Player":
	set(value):

		username = value

		# Update label immediately if ready
		if username_label:
			username_label.text = value


####################################################
# HEALTH
####################################################

var is_dead := false

@export var max_health := 5

@export var health := 5:
	set(value):

		health = clamp(value, 0, max_health)

		if health_bar:
			health_bar.value = health

		if health <= 0 and !is_dead:
			die()


####################################################
# READY
####################################################

func _ready():

	# Wait one frame so replication is finished
	await get_tree().process_frame

	# Authority comes from node name
	set_multiplayer_authority(name.to_int())

	# Local player setup
	if is_multiplayer_authority():

		camera.make_current()

		var hud = get_tree().get_first_node_in_group("hud")

		if hud:
			hud.set_player(self)

	# Username display
	username_label.text = username

	# Health setup
	health_bar.max_value = max_health
	health_bar.value = health

	# Initial animation
	if is_on_floor():
		anim.play(idle_anim_name)
	else:
		anim.play(fly_anim_name)

	print(
		"Authority:",
		multiplayer.get_unique_id(),
		" | Player:",
		get_multiplayer_authority(),
		" | Username:",
		username
	)


####################################################
# PHYSICS
####################################################

func _physics_process(delta):

	# Safety check
	if multiplayer.multiplayer_peer == null:
		return

	####################################################
	# LOCAL PLAYER MOVEMENT
	####################################################

	if is_multiplayer_authority():

		# Gravity
		velocity.y += gravity * delta

		# Horizontal movement
		var direction := Input.get_axis(
			"move_left",
			"move_right"
		)

		# Momentum movement
		if direction != 0:

			velocity.x += (
				direction
				* move_acceleration
				* delta
			)

			velocity.x = clamp(
				velocity.x,
				-max_speed,
				max_speed
			)

		# Drift / inertia
		else:

			velocity.x = lerp(
				velocity.x,
				0.0,
				drift_friction
			)

		# Flap
		if Input.is_action_just_pressed("flap"):

			velocity.y = flap_force

			attack()

		move_and_slide()
		
		if Input.is_action_just_pressed("drop_egg"):

			throw_egg()
			
		####################################################
		# UPDATE SYNC VARIABLES
		####################################################

		if direction > 0:

			facing_right = true

		elif direction < 0:

			facing_right = false

		if is_on_floor() and abs(velocity.y) <= VY_THRESHOLD:

			air_time = 0.0

		else:

			air_time += delta

		var should_fly := (
			air_time > GROUNDED_GRACE
			or Input.is_action_pressed("flap")
		)

		if should_fly:

			current_anim = fly_anim_name

		else:

			current_anim = idle_anim_name

	####################################################
	# VISUALS (RUNS FOR EVERYONE)
	####################################################

	# Animation
	if anim.animation != current_anim:

		anim.play(current_anim)

	# Facing
	anim.flip_h = facing_right

	# Animation speed
	anim.speed_scale = clamp(
		remap(
			abs(velocity.y),
			0.0,
			400.0,
			0.7,
			1.6
		),
		0.7,
		1.6
	)

####################################################
# DAMAGE / COMBAT
####################################################

func die():

	is_dead = true

	print(username, " died")


func attack():

	for area in attack_area.get_overlapping_areas():

		if area.name == "Hurtbox":

			var enemy = area.get_parent()

			if enemy == self:
				continue

			enemy.take_damage.rpc_id(
				enemy.get_multiplayer_authority(),
				1
			)

			print(
				username,
				" hit ",
				enemy.username
			)


@rpc("any_peer")
func take_damage(amount):

	health -= amount


####################################################
# INVENTORY
####################################################

func add_egg(egg : EggData):

	if egg_stack.size() >= MAX_EGGS:

		print("Inventory full")

		return false

	egg_stack.push_back(egg)

	print(
		username,
		" picked up ",
		egg.egg_name
	)

	print(
		"Current inventory:",
		egg_stack.size()
	)

	return true

func throw_egg():

	if egg_stack.is_empty():
		print("No eggs")
		return

	# Remove top egg
	var egg_data = egg_stack.pop_back()

	# Create physical egg
	var egg = egg_object_scene.instantiate()

	# Transfer EggData
	egg.egg_data = egg_data

	# Spawn into world
	get_tree().current_scene.add_child(egg)

	####################################################
	# MOVEMENT DATA
	####################################################

	var current_velocity = velocity
	var speed_amount = current_velocity.length()

	# Normalize speed
	var speed_ratio = clamp(
		speed_amount / 300.0,
		0.0,
		1.0
	)

	####################################################
	# THROW DIRECTION
	####################################################

	var throw_vector := Vector2.ZERO

	# ONLY use movement direction if actually moving
	if speed_amount > 5.0:

		throw_vector = current_velocity.normalized()

	else:

		# Standing still fallback
		if facing_right:
			throw_vector = Vector2.RIGHT
		else:
			throw_vector = Vector2.LEFT

	####################################################
	# SPAWN POSITION
	####################################################

	egg.global_position = global_position + (
		throw_vector * 20.0
	)

	####################################################
	# SMALL MOMENTUM BOOST
	####################################################

	# IMPORTANT:
	# Tiny additional release force.
	# Player momentum should dominate.
	#
	var directional_boost = (
		throw_vector
		* 120.0
		* speed_ratio
	)

	####################################################
	# FINAL VELOCITY
	####################################################

	egg.linear_velocity = (
		current_velocity + directional_boost
	)

	####################################################
	# PREVENT INSTANT RE-PICKUP
	####################################################

	egg.pickup_blocked = true

	var timer = get_tree().create_timer(0.35)

	timer.timeout.connect(func():
		if is_instance_valid(egg):
			egg.pickup_blocked = false
	)

	print(
		username,
		" threw ",
		egg_data.egg_name
	)
	
####################################################
# UTIL
####################################################

func remap(
	value,
	in_min,
	in_max,
	out_min,
	out_max
) -> float:

	return lerp(
		out_min,
		out_max,
		(value - in_min) / (in_max - in_min)
	)
