extends Node

export (Texture) var goal_texture
export (int) var max_needed
export (String) var goal_string
var number_collected = 0

func check_goal(goal_type):
	if goal_type == goal_string:
		update_goal()

func update_goal():
	if number_collected < max_needed:
		number_collected += 1
	if number_collected == max_needed:
		print("goal met")