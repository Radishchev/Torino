extends Area2D

@onready var sprite := $AnimatedSprite2D
@onready var bite_area := $BiteArea

var active := false
var on_cooldown := false

func _ready():
	bite_area.monitoring = false
	sprite.play("idle")


# Connected to your Area2D (e.g., "trigger" area) body_entered signal
func _on_trigger_enter(body):
	# Check if the colliding body has a 'die' method (e.g., the player)
	if not body.has_method("die"):
		return

	# Check if the trap is already performing an action or cooling down
	if active or on_cooldown:
		return

	_activate_trap()


func _activate_trap():
	active = true
	on_cooldown = true

	#####################################
	# ATTACK ANIMATION
	#####################################
	sprite.play("attack")

	# Wait until attack frame 5 begins
	await _wait_for_frame("attack", 5)
	if not is_instance_valid(self): return # Safety Check

	bite_area.monitoring = true  # Start killing here

	# Wait for the attack animation to finish (using signal for reliability)
	await sprite.animation_finished
	if not is_instance_valid(self): return # Safety Check

	#####################################
	# ATTACK TO RETREAT DELAY
	#####################################
	var attack_retreat_delay = 0.5 # TIME DELAY IN SECONDS
	var delay_timer = get_tree().create_timer(attack_retreat_delay)
	await delay_timer.timeout
	if not is_instance_valid(self): return # Safety Check
	
	#####################################
	# RETREAT ANIMATION
	#####################################
	sprite.play("retreat")

	# Keep hitbox active until retreat frame 3 finishes
	await _wait_for_frame("retreat", 3)
	
	# CRITICAL FIX: Safety check for scene reload after player died during wait
	if not is_instance_valid(self): return 
	
	bite_area.monitoring = false # Stop killing here

	# Wait rest of retreat animation
	await sprite.animation_finished
	if not is_instance_valid(self): return # Safety Check

	#####################################
	# Reset
	#####################################
	sprite.play("idle")
	# FIX: Ensure active is set to false right away so the trap can check for the player again
	active = false 

	#####################################
	# Cooldown
	#####################################
	var cooldown_timer = get_tree().create_timer(3.0)
	await cooldown_timer.timeout
	
	# Check validity again before resuming after the timer
	if not is_instance_valid(self): 
		return
		
	on_cooldown = false


# Connected to your BiteArea (Area2D used for killing) body_entered signal
func _on_bite_enter(body):
	# Check if the colliding body has a 'die' method (e.g., the player)
	if body.has_method("die"):
		body.die()


###############################################
# HELPER FUNCTIONS (Crash-proofed)
###############################################

func _wait_for_frame(anim_name: String, target_frame: int):
	# CRITICAL: Check if this node is still valid before starting
	if not is_instance_valid(self):
		return

	while sprite and sprite.animation == anim_name and sprite.frame < target_frame:
		# Await the frame (Crash Point)
		await get_tree().process_frame
		
		# CRITICAL FIX: This MUST be the first line after the await 
		# to catch a scene reload/free triggered by the player death.
		if not is_instance_valid(self): 
			return 
		
		# Check if we were removed from the tree while waiting
		if not is_inside_tree():
			return
