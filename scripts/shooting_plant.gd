extends Area2D

@export_enum("up","down","left","right") var animation_direction := "left"
@export_enum("up","down","left","right") var bullet_direction := "left"

@export var shoot_interval := 2.0
@export var bullet_scene : PackedScene
@export var shoot_frame := 5
@export var bullet_offset := 20

@onready var anim = $AnimatedSprite2D
@onready var timer = $Timer
@onready var muzzle = $Marker2D

var shooting := false

####################################################
# MULTIPLAYER
####################################################

var owner_peer_id := -1

####################################################
# TOUCH DAMAGE
####################################################

var touching_players := {}
var last_damage_times := {}

func _ready():

	timer.wait_time = shoot_interval

	timer.timeout.connect(_shoot)

	anim.frame_changed.connect(
		_on_frame_changed
	)

	body_entered.connect(
		_on_body_entered
	)

	body_exited.connect(
		_on_body_exited
	)

	####################################################
	# DAMAGE TIMER
	####################################################

	var damage_timer = Timer.new()

	damage_timer.wait_time = 2.0

	damage_timer.autostart = true

	damage_timer.timeout.connect(
		_damage_touching_players
	)

	add_child(damage_timer)

	timer.start()


func _shoot():

	####################################################
	# TOUCH DAMAGE
	####################################################

	_damage_touching_players()

	####################################################
	# SHOOT ANIMATION
	####################################################

	shooting = true

	anim.play(
		"shoot_" + animation_direction
	)

func _on_frame_changed():

	if not shooting:
		return

	if anim.frame == shoot_frame:

		_spawn_bullet()


func _spawn_bullet():

	shooting = false

	if bullet_scene:

		var bullet = (
			bullet_scene.instantiate()
		)

		get_tree().current_scene.add_child(
			bullet
		)

		var spawn_pos = muzzle.global_position

		match bullet_direction:

			"left":
				spawn_pos += Vector2(-bullet_offset, 0)

			"right":
				spawn_pos += Vector2(bullet_offset, 0)

			"up":
				spawn_pos += Vector2(0, -bullet_offset)

			"down":
				spawn_pos += Vector2(0, bullet_offset)

		bullet.global_position = spawn_pos

		####################################################
		# MULTIPLAYER OWNER
		####################################################

		bullet.owner_peer_id = owner_peer_id

		bullet.set_direction(
			bullet_direction
		)

####################################################
# BODY ENTERED
####################################################

func _on_body_entered(body):

	####################################################
	# MULTIPLAYER
	####################################################

	if body.has_method("take_damage"):

		var peer_id = (
			body.get_multiplayer_authority()
		)

		touching_players[peer_id] = body

		return

	####################################################
	# SINGLEPLAYER
	####################################################

	if body.has_method("die"):

		body.die()
####################################################
# BODY EXITED
####################################################

func _on_body_exited(body):

	if body.has_method("take_damage"):

		var peer_id = (
			body.get_multiplayer_authority()
		)

		touching_players.erase(peer_id)

####################################################
# DAMAGE PLAYERS
####################################################

func _damage_touching_players():

	####################################################
	# MULTIPLAYER SERVER ONLY
	####################################################

	if multiplayer.has_multiplayer_peer():

		if !multiplayer.is_server():
			return

	for player in touching_players.values():
		var peer_id = (
			player.get_multiplayer_authority()
		)

		####################################################
		# DAMAGE COOLDOWN
		####################################################

		var current_time = (
			Time.get_ticks_msec()
		)

		if last_damage_times.has(peer_id):

			var elapsed = (
				current_time
				- last_damage_times[peer_id]
			)

			if elapsed < 1800:
				continue

		last_damage_times[peer_id] = current_time
		
		if player == null:
			continue

		if !is_instance_valid(player):
			continue

		####################################################
		# MULTIPLAYER DAMAGE
		####################################################

		if player.has_method("take_damage"):

			var authority = (
				player.get_multiplayer_authority()
			)

			####################################################
			# HOST
			####################################################

			if authority == multiplayer.get_unique_id():

				player.take_damage(
					1,
					owner_peer_id
				)

			####################################################
			# CLIENT
			####################################################

			else:

				player.take_damage.rpc_id(
					authority,
					1,
					owner_peer_id
				)
