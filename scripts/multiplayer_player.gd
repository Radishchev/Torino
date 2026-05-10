extends CharacterBody2D

@export var speed := 200.0
@export var flap_force := -300.0
@export var gravity := 900.0

@onready var camera = $Camera2D
@onready var username_label = $UsernameLabel
@onready var health_bar = $HealthBar

var egg_stack : Array[EggData] = []

const MAX_EGGS := 3

# Multiplayer synced username
@export var username := "Player":
	set(value):
		username = value

		# Update label immediately if ready
		if username_label:
			username_label.text = value

var is_dead := false

@export var max_health := 5
@export var health := 5:
	set(value):

		health = clamp(value, 0, max_health)

		if health_bar:

			health_bar.value = health

		if health <= 0 and !is_dead:

			die()

@onready var attack_area = $AttackArea

func _ready():

	# Wait one frame so replication is finished
	await get_tree().process_frame

	# IMPORTANT
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
	
	print(
		"Authority:",
		multiplayer.get_unique_id(),
		" | Player:",
		get_multiplayer_authority(),
		" | Username:",
		username
	)


func _physics_process(delta):

	# Safety check
	if multiplayer.multiplayer_peer == null:
		return

	# Only local player moves
	if !is_multiplayer_authority():
		return

	velocity.y += gravity * delta

	var direction = Input.get_axis(
		"move_left",
		"move_right"
	)

	velocity.x = direction * speed

	if Input.is_action_just_pressed("flap"):

		velocity.y = flap_force
		
		attack()

	move_and_slide()

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
