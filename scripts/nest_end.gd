extends Area2D

signal maze_solved

@export var main_menu_scene: String = "res://scenes/Main_Menu.tscn"

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func _on_body_entered(body: Node2D) -> void:
	# Check if it's a bird
	if body.is_in_group("bird"):
		_handle_solved(body)

func _on_area_entered(area: Area2D) -> void:
	# Also check for RoomDetector if body doesn't trigger
	var p = area.get_parent()
	if p and p.is_in_group("bird"):
		_handle_solved(p)

func _handle_solved(player: Node2D) -> void:
	print("[Nest] Maze solved by player: ", player.name)
	maze_solved.emit()
	
	# Only the local authority player who solved it transitions to main menu
	if player.has_method("is_multiplayer_authority") and player.is_multiplayer_authority():
		print("[Nest] Local player solved maze. Transitioning to Main Menu...")
		# Add a slight delay for dramatic effect/sound if wanted, but here immediate
		get_tree().change_scene_to_file(main_menu_scene)
