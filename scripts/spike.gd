extends Area2D

func _ready():
	connect("body_entered", _on_body_entered)


func _on_body_entered(body):
	if body.has_method("die"):
		body.die()
