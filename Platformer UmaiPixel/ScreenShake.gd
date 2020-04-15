extends Node2D

var current_shake_priority = 0

func move_camera(vector):
	get_parent().get_node("Player/Camera2D").offset = \
		Vector2(rand_range(-vector.x, vector.x), rand_range(-vector.y, vector.y))

func screen_shake(shake_length, shake_power, shake_priority):
	if shake_priority > current_shake_priority:
		current_shake_priority = shake_priority
		# Calculate in betweens of two values (or two animations)
		$Tween.interpolate_method(self,
			"move_camera",
			Vector2(shake_power, shake_power), # starting value
			Vector2.ZERO, # end value
			shake_length, # number of seconds tween will take to finish
			Tween.TRANS_SINE, # how the numbers get calculated
			Tween.EASE_OUT, # easing
			0 # delay
		) # call move_camera with the in between values calculated
		$Tween.start()

func _on_Tween_tween_completed(object, key):
	current_shake_priority = 0
