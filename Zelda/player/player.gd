extends entity

var state = "default"

var keys = 0

func _init():
	TYPE = "PLAYER"
	SPEED = 70
	# null to avoid knockback
	DAMAGE = null
	MAXHEALTH = 16
	health = MAXHEALTH

func _physics_process(delta):
	match state:
		"default": state_default()
		"swing": state_swing()
	keys = min(keys, 9)

func state_default():
	controls_loop()
	movement_loop()
	spritedir_loop()
	damage_loop()

	if movedir != dir.center:
		if is_pushing():
			anim_switch("push")
		else:
			anim_switch("walk")
	else:
		anim_switch("idle")

	if Input.is_action_just_pressed("a"):
		use_item(preload("res://items/sword.tscn"))

func is_pushing():
	var test_vector
	if is_on_wall():
		# make sure player is facing AND pressing a specific direction
		match spritedir:
			"left": test_vector = dir.left
			"right": test_vector = dir.right
			"up": test_vector = dir.up
			"down": test_vector = dir.down
		# test if there's a collision to the given direction
		# transform is where the player is
		return test_move(transform, test_vector)
	return false

func state_swing():
	anim_switch("idle")
	movement_loop()
	damage_loop()
	movedir = dir.center

func controls_loop():
	var LEFT	= Input.is_action_pressed("ui_left")
	var RIGHT	= Input.is_action_pressed("ui_right")
	var UP		= Input.is_action_pressed("ui_up")
	var DOWN	= Input.is_action_pressed("ui_down")

	movedir.x = -int(LEFT) + int(RIGHT)
	movedir.y = -int(UP) + int(DOWN)






