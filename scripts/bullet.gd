extends CharacterBody2D

@export var speed := 220

var direction := Vector2.ZERO

@onready var anim = $AnimatedSprite2D
@onready var hitbox = $CollisionShape2D


# MULTIPLAYER


var owner_peer_id := -1

var hit_something := false


func set_direction(dir):

	match dir:

		"left":
			direction = Vector2.LEFT
			anim.play("left")
			hitbox.position = Vector2(-8, 0)

		"right":
			direction = Vector2.RIGHT
			anim.play("right")
			hitbox.position = Vector2(8, 0)

		"up":
			direction = Vector2.UP
			anim.play("up")
			hitbox.position = Vector2(0, -8)

		"down":
			direction = Vector2.DOWN
			anim.play("down")
			hitbox.position = Vector2(0, 8)


func _physics_process(delta):

	if hit_something:
		return

	velocity = direction * speed

	move_and_slide()

	
	# DETECT COLLISIONS
	

	for i in get_slide_collision_count():

		var collision = get_slide_collision(i)

		var collider = collision.get_collider()

		if collider == null:
			continue

		
		# MULTIPLAYER PLAYER
		

		if collider.has_method("take_damage"):

			hit_something = true

			
			# CLIENT VISUAL BULLET
			

			if multiplayer.has_multiplayer_peer():

				if !multiplayer.is_server():

					queue_free()
					return

			
			# SERVER DAMAGE
			

			var authority = (
				collider.get_multiplayer_authority()
			)

			
			# HOST
			

			if authority == multiplayer.get_unique_id():

				collider.take_damage(
					2,
					owner_peer_id
				)

			
			# CLIENT
			

			else:

				collider.take_damage.rpc_id(
					authority,
					2,
					owner_peer_id
				)

			queue_free()
			return

		
		# SINGLEPLAYER PLAYER
		

		if collider.has_method("die"):

			hit_something = true

			collider.die()

			queue_free()
			return

		
		# HIT WALL
		

		hit_something = true

		queue_free()
		return


func _on_visible_on_screen_notifier_2d_screen_exited():

	queue_free()
