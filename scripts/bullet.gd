extends CharacterBody2D

@export var speed := 220

var direction := Vector2.ZERO

@onready var anim = $AnimatedSprite2D
@onready var hitbox = $CollisionShape2D


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

	velocity = direction * speed
	move_and_slide()

	# Detect collisions
	for i in get_slide_collision_count():

		var collision = get_slide_collision(i)
		var collider = collision.get_collider()

		if collider == null:
			continue

		if collider.name == "Player":
			collider.die()
			queue_free()
			return

		# If it hits anything else (like walls)
		queue_free()


func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free()
