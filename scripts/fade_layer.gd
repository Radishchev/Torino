extends CanvasLayer

@onready var rect = $ColorRect


func _ready():
	rect.modulate.a = 0
	rect.hide()


func fade_out(time := 1.0):

	rect.show()
	rect.modulate.a = 0

	var tween = create_tween()
	tween.tween_property(rect, "modulate:a", 1.0, time)

	await tween.finished


func fade_in(time := 1.0):

	var tween = create_tween()
	tween.tween_property(rect, "modulate:a", 0.0, time)

	await tween.finished
	rect.hide()
