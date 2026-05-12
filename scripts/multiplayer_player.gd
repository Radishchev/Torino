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
@onready var attack_area = $AttackArea
@onready var anim = $AnimatedSprite2D
@onready var world_hearts = $WorldHearts

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

		####################################################
		# LOCAL HUD HEARTS
		####################################################

		if is_multiplayer_authority():

			var hud = (
				get_tree()
				.get_first_node_in_group("hud")
			)

			if hud:

				hud.update_hearts(
					health,
					max_health
				)

		####################################################
		# WORLD HEARTS
		####################################################

		update_world_hearts()

		####################################################
		# DEATH
		####################################################

		if health <= 0 and !is_dead:

			die()

func update_world_hearts():

	if world_hearts == null:
		return
	
	# Remove old hearts
	for child in world_hearts.get_children():

		child.queue_free()

	# Create hearts
	for i in range(max_health):

		var heart = TextureRect.new()

		heart.texture = preload(
			"res://assets/heart.png"
		)

		heart.custom_minimum_size = Vector2(12, 12)

		heart.expand_mode = (
			TextureRect.EXPAND_IGNORE_SIZE
		)

		heart.stretch_mode = (
			TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		)

		# Empty hearts become transparent
		if i >= health:

			continue

		world_hearts.add_child(heart)

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
		
		world_hearts.visible = false

		var hud = get_tree().get_first_node_in_group("hud")

		if hud:
			hud.set_player(self)
			hud.update_hearts(
				health,
				max_health
			)

	# Username display
	username_label.text = username

	# Health setup
	update_world_hearts()
	#health_bar.max_value = max_health
	var hud = get_tree().get_first_node_in_group("hud")

	if hud and is_multiplayer_authority():

		hud.update_hearts(
			health,
			max_health
		)

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
	var hud = get_tree().get_first_node_in_group("hud")

	if hud and is_multiplayer_authority():

		hud.update_eggs(egg_stack)

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

	####################################################
	# REMOVE EGG FROM INVENTORY
	####################################################

	var egg_data = egg_stack.pop_back()

	# Update HUD
	var hud = (
		get_tree()
		.get_first_node_in_group("hud")
	)

	if hud and is_multiplayer_authority():

		hud.update_eggs(egg_stack)

	####################################################
	# MOVEMENT DATA
	####################################################

	var current_velocity = velocity

	var speed_amount = (
		current_velocity.length()
	)

	var speed_ratio = clamp(
		speed_amount / 300.0,
		0.0,
		1.0
	)

	####################################################
	# THROW DIRECTION
	####################################################

	var throw_vector := Vector2.ZERO

	# Use movement direction
	if speed_amount > 5.0:

		throw_vector = (
			current_velocity.normalized()
		)

	# Standing still fallback
	else:

		if facing_right:

			throw_vector = Vector2.RIGHT

		else:

			throw_vector = Vector2.LEFT

	####################################################
	# THROW VELOCITY
	####################################################

	var directional_boost = (
		throw_vector
		* 120.0
		* speed_ratio
	)

	var final_velocity = (
		current_velocity
		+ directional_boost
	)

	####################################################
	# THROW POSITION
	####################################################

	var spawn_position = (
		global_position
		+ (throw_vector * 20.0)
	)

	####################################################
	# CREATE EGG
	####################################################

	var egg = egg_object_scene.instantiate()

	egg.egg_data = egg_data

	get_tree().current_scene.add_child(egg)

	egg.global_position = spawn_position

	egg.linear_velocity = final_velocity

	####################################################
	# PREVENT INSTANT RE-PICKUP
	####################################################

	egg.pickup_blocked = true

	var timer = (
		get_tree().create_timer(0.35)
	)

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
