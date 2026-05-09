extends CharacterBody2D

@export var speed := 200.0
@export var flap_force := -300.0
@export var gravity := 900.0

@onready var camera = $Camera2D


func _ready():

	await get_tree().process_frame

	set_multiplayer_authority(name.to_int())

	# Activate local camera only
	if is_multiplayer_authority():

		camera.make_current()

		var hud = get_tree().get_first_node_in_group("hud")

		if hud:
			hud.set_player(self)

	print(
		"Authority:",
		multiplayer.get_unique_id(),
		" | Player:",
		get_multiplayer_authority()
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

	move_and_slide()
