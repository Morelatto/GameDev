extends Area2D

const TURN_SPEED = 180 # how fast the ship will turn
const MOVE_SPEED = 150 # max speed the player can move
const ACC = 0.05 # acceleration %
const DEC = 0.01 # deceleration %

var motion = Vector2.ZERO # ship's actual move direction (not the desired move direction)

var screen_size
var screen_buffer = 8 # how far the ship can move off screen before it reappears on the other side

func _ready():
	screen_size = get_viewport_rect().size

# called every single frame
func _process(delta):
	if Input.is_action_pressed("ui_left"):
		# property of player node
		rotation_degrees -= TURN_SPEED * delta # multiply by delta to make sure timing is correct
	if Input.is_action_pressed("ui_right"):
		rotation_degrees += TURN_SPEED * delta
	
	# move direction is the direction you're facing and want to go
	var movedir = Vector2.RIGHT.rotated(rotation)
	
	# acceleration
	if Input.is_action_pressed("ui_up"):
		# smoothly animates motion (where you're going) 
		# based off moving direction (where you're trying to go) 
		# by the acceleration value
		motion = motion.linear_interpolate(movedir, ACC) # lerp towards desired move direction
	else:
		# every frame that ui_up is not pressed 
		# it is going from motion to stillness 
		# by the deceleration value
		motion = motion.linear_interpolate(Vector2.ZERO, DEC)  # lerp towards stillness
	position += motion * MOVE_SPEED * delta
	
	# screen wrapping
	position.x = wrapf(position.x, -screen_buffer, screen_size.x + screen_buffer)
	position.y = wrapf(position.y, -screen_buffer, screen_size.y + screen_buffer)





