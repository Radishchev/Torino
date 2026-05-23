extends CharacterBody2D


####################################################
# MOVEMENT
####################################################

@export var gravity := 900.0
@export var flap_force := -300.0

@export var move_acceleration := 180.0
@export var max_speed := 180.0
@export var drift_friction := 0.03

var spectating := false

var default_camera_zoom := Vector2.ONE

var spectate_zoom := Vector2(3.4, 3.4)

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

var shake_strength := 0.0
####################################################
# NODES
####################################################

@onready var camera = $Camera2D
@onready var username_label = $UIContainer/UsernameLabel
@onready var attack_area = $AttackArea
@onready var anim = $AnimatedSprite2D
@onready var world_hearts = $UIContainer/WorldHearts
@onready var collision = $CollisionShape2D

@onready var weapon_holder = $WeaponHolder

@onready var knife_hitbox = (
	$WeaponHolder/KnifeHitbox
)

@onready var hurt_sound = $HurtSound
@onready var chirp_sound = $ChirpSound

####################################################
# INVENTORY
####################################################
@export var egg_object_scene : PackedScene

var egg_stack : Array[EggData] = []

const MAX_EGGS := 3

var active_respawn_egg: Node = null
var has_respawn_egg := false
var respawn_egg_position := Vector2.ZERO

@export var has_dagger := false
var dagger_timer_id := 0

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

var last_attacker_peer_id := -1
var is_invincible := false

@export var blink_visible := true:
	set(value):

		blink_visible = value

		if anim:

			anim.visible = value

		if username_label:

			username_label.visible = value

		if world_hearts:

			if !is_multiplayer_authority():

				world_hearts.visible = value

@export var respawn_time := 5.0

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
			if is_multiplayer_authority():
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
	#await get_tree().process_frame
	
	var sync = get_node("MultiplayerSynchronizer")

	
	
	# Authority comes from node name
	#set_multiplayer_authority(name.to_int())

	# Local player setup
	if is_multiplayer_authority():
	
		camera.make_current()
		
		default_camera_zoom = camera.zoom
		
		world_hearts.visible = false
		
		@warning_ignore("confusable_local_declaration")
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
	
	weapon_holder.visible = false
	
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

func _process(delta):

	if !is_multiplayer_authority():
		return

	if shake_strength > 0:

		camera.offset = Vector2(
			randf_range(
				-shake_strength,
				shake_strength
			),
			randf_range(
				-shake_strength,
				shake_strength
			)
		)

		shake_strength = lerp(
			shake_strength,
			0.0,
			10.0 * delta
		)

	else:

		camera.offset = Vector2.ZERO

####################################################
# PHYSICS
####################################################

func _physics_process(delta):

	####################################################
	# SAFETY CHECK
	####################################################

	if multiplayer.multiplayer_peer == null:
		return

	####################################################
	# MATCH FINISHED
	####################################################

	var level = (
		get_tree()
		.get_first_node_in_group("level")
	)

	if level and level.match_finished:
		return

	####################################################
	# LOCAL PLAYER MOVEMENT
	####################################################


	####################################################
	# LOCAL PLAYER MOVEMENT
	####################################################
	
	weapon_holder.visible = has_dagger
	knife_hitbox.monitoring = has_dagger
	if is_multiplayer_authority():
		####################################################
		# DEAD PLAYERS CANNOT CONTROL
		####################################################

		if is_dead:
			return
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
			
			####################################################
			# RANDOM CHIRP
			####################################################

			if randf() < 0.2:

				chirp_sound.pitch_scale = randf_range(
					0.92,
					1.08
				)

				chirp_sound.play()

		move_and_slide()
		
		dagger_attack()
		
		
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
	
	weapon_holder.visible = has_dagger
	knife_hitbox.monitoring = has_dagger
	
	# Animation
	if anim.animation != current_anim:

		anim.play(current_anim)

	# Facing
	anim.flip_h = facing_right
	
	if facing_right:

		weapon_holder.scale.x = 1

	else:

		weapon_holder.scale.x = -1
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

	if is_dead:
		return

	####################################################
	# RESPAWN EGG
	####################################################

	if has_respawn_egg:

		if is_instance_valid(active_respawn_egg):

			print(username, " respawned from egg")

			var respawn_position = (
				respawn_egg_position
			)

			####################################################
			# CONSUME EGG
			####################################################

			if multiplayer.is_server():

				active_respawn_egg.queue_free()

			clear_respawn_egg.rpc()

			####################################################
			# REMOVE TEMP EFFECTS
			####################################################

			has_dagger = false
			knife_hitbox.monitoring = false
			weapon_holder.visible = false

			####################################################
			# RESPAWN
			####################################################

			is_dead = true

			respawn(
				respawn_position,
				true,
				true,
				1
			)

			return

	is_dead = true

	####################################################
	# SHOW LEADERBOARD
	####################################################

	if is_multiplayer_authority():

		var hud = (
			get_tree()
			.get_first_node_in_group("hud")
		)

		if hud:

			hud.show_leaderboard()

		spectate_killer()

	####################################################
	# SYNCHRONIZED VISIBILITY
	####################################################

	blink_visible = false

	####################################################
	# REMOVE TEMP EFFECTS
	####################################################

	has_dagger = false

	knife_hitbox.monitoring = false

	####################################################
	# AWARD KILL
	####################################################

	if last_attacker_peer_id != -1:

		####################################################
		# SELF KILL
		####################################################

		if (
			last_attacker_peer_id
			== multiplayer.get_unique_id()
		):

			NetworkManager.request_remove_kill.rpc_id(
				1,
				last_attacker_peer_id
			)

		####################################################
		# NORMAL KILL
		####################################################

		else:

			NetworkManager.request_add_kill.rpc_id(
				1,
				last_attacker_peer_id
			)

	print(
		username,
		" died to peer:",
		last_attacker_peer_id
	)

	####################################################
	# CLEAR INVENTORY
	####################################################

	egg_stack.clear()

	sync_inventory.rpc_id(
		get_multiplayer_authority(),
		get_inventory_paths()
	)

	####################################################
	# DISABLE COLLISIONS
	####################################################

	collision.disabled = true

	####################################################
	# HIDE LOCAL HEARTS
	####################################################

	world_hearts.visible = false

	####################################################
	# RESPAWN TIMER
	####################################################

	respawn()
	

func respawn(
	custom_position := Vector2.ZERO,
	use_custom_position := false,
	instant := false,
	respawn_health := -1
):

	if !instant:

		await get_tree().create_timer(
			respawn_time
		).timeout

	####################################################
	# FIND LEVEL
	####################################################

	var level = (
		get_tree()
		.get_first_node_in_group("level")
	)

	if level == null:
		return

	####################################################
	# RESPAWN POSITION
	####################################################

	if use_custom_position:

		global_position = custom_position

	else:

		var spawn_points = (
			level.spawn_points.get_children()
		)

		if spawn_points.is_empty():
			return

		var spawn = spawn_points.pick_random()

		global_position = spawn.global_position
	
	camera.global_position = global_position

	####################################################
	# RESET HEALTH
	####################################################

	if respawn_health == -1:

		health = max_health

	else:

		health = respawn_health

	is_dead = false
	
	####################################################
	# RESET TEMP EFFECTS
	####################################################

	has_dagger = false

	weapon_holder.visible = false

	knife_hitbox.monitoring = false
	
	####################################################
	# STOP SPECTATING
	####################################################

	spectating = false

	camera.zoom = default_camera_zoom
	
	####################################################
	# HIDE LEADERBOARD
	####################################################

	if is_multiplayer_authority():

		var hud = (
			get_tree()
			.get_first_node_in_group("hud")
		)

		if hud:

			hud.hide_leaderboard()

	####################################################
	# RESTORE COLLISIONS
	####################################################

	collision.disabled = false

	####################################################
	# TEMP INVINCIBILITY
	####################################################

	is_invincible = true

	var invincible_time := 3.0

	var elapsed := 0.0

	while elapsed < invincible_time:

		####################################################
		# BLINK SPEED INCREASES OVER TIME
		####################################################

		var progress = (
			elapsed / invincible_time
		)

		var blink_interval = lerp(
			0.25,
			0.05,
			progress
		)

		####################################################
		# TOGGLE VISIBILITY
		####################################################

		blink_visible = !blink_visible
		
		notify_property_list_changed()

		await get_tree().create_timer(
			blink_interval
		).timeout

		elapsed += blink_interval

	####################################################
	# FINAL VISIBLE STATE
	####################################################

	anim.visible = true

	username_label.visible = true

	if !is_multiplayer_authority():

		world_hearts.visible = true

	####################################################
	# END INVINCIBILITY
	####################################################

	is_invincible = false
	
	blink_visible = true

	print(username, " respawned")
	

@rpc("any_peer", "call_local")
func set_respawn_egg(
	egg_path: NodePath,
	pos: Vector2
):

	active_respawn_egg = get_node_or_null(
		egg_path
	)

	has_respawn_egg = (
		active_respawn_egg != null
	)

	respawn_egg_position = pos

@rpc("call_local")
func clear_respawn_egg():

	active_respawn_egg = null
	has_respawn_egg = false
	
func attack():
	
	if is_dead:
		return

	for area in attack_area.get_overlapping_areas():

		if area.name == "Hurtbox":

			var enemy = area.get_parent()

			if enemy == self:
				continue

			enemy.take_damage.rpc_id(
				enemy.get_multiplayer_authority(),
				1,
				multiplayer.get_unique_id()
			)

			print(
				username,
				" hit ",
				enemy.username
			)


func dagger_attack():

	if is_dead:
		return

	if !has_dagger:
		return

	for area in knife_hitbox.get_overlapping_areas():

		if area.name == "Hurtbox":

			var enemy = area.get_parent()

			if enemy == self:
				continue

			enemy.take_damage.rpc_id(
				enemy.get_multiplayer_authority(),
				999,
				multiplayer.get_unique_id()
			)

			print(
				username,
				" stabbed ",
				enemy.username
			)

@rpc("any_peer", "call_local")
func activate_dagger(duration := 3.0):

	####################################################
	# ENABLE DAGGER
	####################################################

	has_dagger = true

	####################################################
	# UNIQUE TIMER ID
	####################################################

	dagger_timer_id += 1

	var current_timer = dagger_timer_id

	print(
		username,
		" activated dagger"
	)

	####################################################
	# WAIT
	####################################################

	await get_tree().create_timer(
		duration
	).timeout

	####################################################
	# NEWER DAGGER ACTIVATED
	####################################################

	if current_timer != dagger_timer_id:
		return

	####################################################
	# PLAYER MAY HAVE DIED
	####################################################

	if is_dead:
		return

	####################################################
	# REMOVE DAGGER
	####################################################

	has_dagger = false

	print(
		username,
		" dagger expired"
	)
	

@rpc("any_peer")
func take_damage(
	amount,
	attacker_peer_id
):
	if is_dead:
		return

	if is_invincible:
		return
	####################################################
	# STORE ATTACKER
	####################################################
	if is_multiplayer_authority():

		shake_strength = 5.0
	last_attacker_peer_id = attacker_peer_id

	print(
		username,
		" damaged by peer:",
		last_attacker_peer_id
	)

	####################################################
	# APPLY DAMAGE
	####################################################
	hurt_sound.play()
	flash_damage()
	health -= amount


func flash_damage():

	anim.modulate = Color(1, 0.4, 0.4)

	await get_tree().create_timer(
		0.12
	).timeout

	anim.modulate = Color.WHITE
@rpc("any_peer")
func heal(amount):

	health += amount

####################################################
# INVENTORY
####################################################

func get_inventory_paths():

	var paths := []

	for egg in egg_stack:

		paths.push_back(
			egg.resource_path
		)

	return paths


@rpc("any_peer", "call_local")
func sync_inventory(paths : Array):

	####################################################
	# REBUILD LOCAL INVENTORY
	####################################################

	egg_stack.clear()

	for path in paths:

		var egg_data = load(path)

		if egg_data:

			egg_stack.push_back(egg_data)

	####################################################
	# UPDATE HUD
	####################################################

	if is_multiplayer_authority():

		var hud = (
			get_tree()
			.get_first_node_in_group("hud")
		)

		if hud:

			hud.update_eggs(egg_stack)

	print(
		"Inventory synced:",
		egg_stack.size()
	)


func add_egg(egg : EggData):

	if egg_stack.size() >= MAX_EGGS:

		print("Inventory full")

		return false

	####################################################
	# SERVER INVENTORY
	####################################################

	egg_stack.push_back(egg)

	####################################################
	# SYNC TO OWNER
	####################################################

	sync_inventory.rpc_id(
		get_multiplayer_authority(),
		get_inventory_paths()
	)

	####################################################
	# DEBUG
	####################################################

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


@rpc("any_peer")
func request_remove_egg():

	####################################################
	# ONLY SERVER MODIFIES TRUE INVENTORY
	####################################################

	if !multiplayer.is_server():
		return

	if egg_stack.is_empty():
		return

	####################################################
	# REMOVE SERVER EGG
	####################################################

	egg_stack.pop_back()

	####################################################
	# RESYNC CLIENT
	####################################################

	sync_inventory.rpc_id(
		get_multiplayer_authority(),
		get_inventory_paths()
	)


####################################################
# THROW EGG
####################################################

func throw_egg():
	
	if is_dead:
		return
		
	if egg_stack.is_empty():

		print("No eggs")
		return

	####################################################
	# LOCAL PREDICTION
	####################################################

	var egg_data = egg_stack.pop_back()

	####################################################
	# CLIENT REQUESTS SERVER REMOVAL
	####################################################

	if !multiplayer.is_server():

		request_remove_egg.rpc_id(1)

	####################################################
	# LOCAL HUD UPDATE
	####################################################

	if is_multiplayer_authority():

		var hud = (
			get_tree()
			.get_first_node_in_group("hud")
		)

		if hud:

			hud.update_eggs(egg_stack)
	print(
		"Throwing egg as peer:",
		multiplayer.get_unique_id()
	)
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

	if speed_amount > 5.0:

		throw_vector = (
			current_velocity.normalized()
		)

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
		* 200.0
		* speed_ratio
	)
	
	####################################################
	# REMOVE DOWNWARD MOMENTUM
	####################################################

	if current_velocity.y > 0:

		current_velocity.y = 0
	
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
	# HOST SPAWNS DIRECTLY
	####################################################

	if multiplayer.is_server():

		request_throw_egg(
			egg_data.resource_path,
			spawn_position,
			final_velocity,
			multiplayer.get_unique_id()
		)

	####################################################
	# CLIENT REQUESTS SERVER
	####################################################

	else:

		request_throw_egg.rpc_id(
			1,
			egg_data.resource_path,
			spawn_position,
			final_velocity,
			multiplayer.get_unique_id()
		)

	####################################################
	# DEBUG
	####################################################

	print(
		username,
		" threw ",
		egg_data.egg_name
	)


####################################################
# NETWORK THROW
####################################################

@rpc("any_peer")
func request_throw_egg(
	egg_resource_path : String,
	spawn_position : Vector2,
	start_velocity : Vector2,
	owner_peer_id : int
):

	####################################################
	# ONLY SERVER SPAWNS
	####################################################
	print(
		"Server received throw request from:",
		owner_peer_id
	)
	if !multiplayer.is_server():
		return

	var egg_data = load(egg_resource_path)

	if egg_data == null:
		return

	####################################################
	# GET LEVEL
	####################################################

	var level = (
		get_tree()
		.get_first_node_in_group("level")
	)

	if level == null:
		return

	####################################################
	# USE NETWORK SPAWNER
	####################################################

	level.spawn_egg(
		egg_data,
		spawn_position,
		start_velocity,
		owner_peer_id
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


func spectate_killer():

	if last_attacker_peer_id == -1:
		return

	####################################################
	# FIND KILLER
	####################################################

	var level = (
		get_tree()
		.get_first_node_in_group("level")
	)

	if level == null:
		return

	var killer = level.players.get_node_or_null(
		str(last_attacker_peer_id)
	)

	if killer == null:
		return

	spectating = true

	####################################################
	# CAMERA ZOOM
	####################################################

	camera.zoom = spectate_zoom

	####################################################
	# FOLLOW LOOP
	####################################################

	while spectating and is_dead:

		camera.global_position = lerp(
			camera.global_position,
			killer.global_position,
			0.08
		)

		await get_tree().process_frame
