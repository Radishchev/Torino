extends Node2D

@export var target_nest_path: NodePath
@export var save_checkpoint := true

var activated := false


func _ready():
	$Area2D.body_entered.connect(_on_body_entered)


func _on_body_entered(body):

	if activated:
		return

	if body.name != "Player":
		return

	activated = true

	var player = body

	print("🪺 Nest touched:", name)

	# Snap bird to this nest
	player.global_position = $Marker2D.global_position

	print("📍 Player snapped to nest at:", $Marker2D.global_position)

	await get_tree().create_timer(1.0).timeout

	if save_checkpoint:
		save_game()

	# Teleport to next nest if specified
	if target_nest_path != NodePath(""):

		await Fade.fade_out(1.0)

		var target_nest = get_node(target_nest_path)

		if target_nest:
			var new_pos = target_nest.get_node("Marker2D").global_position

			player.global_position = new_pos
			player.spawn_point = new_pos

			print("➡ Teleported to:", new_pos)

		await Fade.fade_in(1.0)



func save_game():

	var nest_node

	if target_nest_path != NodePath(""):
		nest_node = get_node(target_nest_path)
	else:
		nest_node = self

	var save_data = {
		"level": get_tree().current_scene.scene_file_path,
		"nest": nest_node.get_path()
	}

	var file = FileAccess.open("user://save.dat", FileAccess.WRITE)
	file.store_var(save_data)

	print("💾 Game saved. Spawn nest:", nest_node.get_path())
