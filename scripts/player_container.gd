extends Node2D

@onready var player = $Player
@onready var camera = $Camera2D
@onready var hud = $HUD

func _ready():
	var is_local = player.is_multiplayer_authority()

	# Camera only for local player
	camera.enabled = is_local

	# HUD only for local player
	hud.visible = is_local
