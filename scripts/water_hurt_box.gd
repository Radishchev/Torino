extends Area2D

func _ready():
	connect("body_entered", _on_body_entered)

func _on_body_entered(body):
	print("Bird touched water")
	if body.is_in_group("bird"):
		body.die()
