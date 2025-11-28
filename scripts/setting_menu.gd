extends Node

@onready var music_slider = $Music_Slider
@onready var sound_slider = $Sound_Slider

var original_music_volume: float
var original_sound_volume: float

func _ready() -> void:
	# Store the volumes as soon as the menu opens
	original_music_volume = Global.current_music_volume
	original_sound_volume = Global.current_sound_volume

	# Load slider positions
	music_slider.value = original_music_volume
	sound_slider.value = original_sound_volume

	# Apply temporary preview volumes
	_on_music_slider_value_changed(original_music_volume)
	_on_sound_slider_value_changed(original_sound_volume)


func _on_back_button_pressed() -> void:
	# Restore old volumes (undo preview)
	var music_bus = AudioServer.get_bus_index("Music")
	var sound_bus = AudioServer.get_bus_index("Sound")

	AudioServer.set_bus_volume_db(music_bus, linear_to_db(original_music_volume))
	AudioServer.set_bus_mute(music_bus, original_music_volume < 0.01)

	AudioServer.set_bus_volume_db(sound_bus, linear_to_db(original_sound_volume))
	AudioServer.set_bus_mute(sound_bus, original_sound_volume < 0.01)

	# Return to the menu
	get_tree().change_scene_to_file("res://scenes/Main_Menu.tscn")


func _on_music_slider_value_changed(value: float) -> void:
	var music_bus = AudioServer.get_bus_index("Music")
	var db = linear_to_db(value)
	AudioServer.set_bus_volume_db(music_bus, db)
	AudioServer.set_bus_mute(music_bus, value < 0.01)


func _on_sound_slider_value_changed(value: float) -> void:
	var sound_bus = AudioServer.get_bus_index("Sound")
	var db = linear_to_db(value)
	AudioServer.set_bus_volume_db(sound_bus, db)
	AudioServer.set_bus_mute(sound_bus, value < 0.01)


func _on_save_button_pressed() -> void:
	# Save the preview values
	Global.current_music_volume = music_slider.value
	Global.current_sound_volume = sound_slider.value

	get_tree().change_scene_to_file("res://scenes/Main_Menu.tscn")
