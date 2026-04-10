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


func _ready():

	timer.wait_time = shoot_interval
	timer.timeout.connect(_shoot)

	anim.frame_changed.connect(_on_frame_changed)
	body_entered.connect(_on_body_entered)

	timer.start()


func _shoot():

	shooting = true
	anim.play("shoot_" + animation_direction)


func _on_frame_changed():

	if not shooting:
		return

	if anim.frame == shoot_frame:

		_spawn_bullet()


func _spawn_bullet():

	shooting = false

	if bullet_scene:

		var bullet = bullet_scene.instantiate()
		get_tree().current_scene.add_child(bullet)

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
		bullet.set_direction(bullet_direction)


func _on_body_entered(body):
	if body.has_method("die"):
		body.die()
