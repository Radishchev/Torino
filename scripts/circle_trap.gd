extends Area2D

@onready var anim = $AnimatedSprite2D
@onready var hitbox = $CollisionShape2D


func _ready():
	anim.frame_changed.connect(_on_frame_changed)


func _on_frame_changed():

	var frame = anim.frame

	# Frames 2 → 9 use larger hitbox
	if frame >= 2 and frame <= 9:
		_set_hitbox_size(30)
	else:
		_set_hitbox_size(20)


func _set_hitbox_size(size):

	var shape = hitbox.shape

	# If using CircleShape2D
	if shape is CircleShape2D:
		shape.radius = size

	# If using RectangleShape2D
	elif shape is RectangleShape2D:
		shape.size = Vector2(size, size)
