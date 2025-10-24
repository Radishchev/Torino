extends CharacterBody2D

@export var gravity: float = 1400.0
@export var flap_strength: float = -360.0


func _physics_process(delta: float) -> void:
	# Apply gravity each frame
	velocity.y += gravity * delta

	# Flap upward when pressing Space
	if Input.is_action_just_pressed("flap"):
		velocity.y = flap_strength

	# Apply velocity to the player
	move_and_slide()
