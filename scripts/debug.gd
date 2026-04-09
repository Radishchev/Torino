extends Node


func _ready():
	print("🛠 Debug system loaded")


func _input(event):

	# Press F1 → Clear save
	if event.is_action_pressed("debug_clear_save"):
		clear_save()

	# Press F2 → Reload scene
	if event.is_action_pressed("debug_reload_scene"):
		get_tree().reload_current_scene()


func clear_save():

	if FileAccess.file_exists("user://save.dat"):
		DirAccess.remove_absolute("user://save.dat")
		print("🧹 Save file cleared")

	else:
		print("⚠ No save file found")
