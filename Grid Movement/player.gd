extends Sprite

var speed = 256
var tile_size = 64

var last_position: Vector2
var target_position: Vector2 # where the player is trying to go
var movedir: Vector2

onready var ray = $RayCast2D

func _ready():
	# grid movement
	position = position.snapped(Vector2(tile_size, tile_size))
	last_position = position
	target_position = position

func _process(delta):
	# MOVEMENT
	if ray.is_colliding():
		# if the player hits a wall it will be snapped to where it was before it hit the wall
		position = last_position
		target_position = last_position
	else:
		position += speed * movedir * delta

		# movement snap
		if position.distance_to(last_position) >= tile_size - speed * delta:
			# makes sure if key is only pressed once movement will continue to the next tile		
			position = target_position

	# IDLE
	if position == target_position:
		# only check movement keys if already at target (idle)
		get_movedir()
		last_position = position
		# grid movement
		target_position += movedir * tile_size

func get_movedir():
	var LEFT	= Input.is_action_pressed("ui_left")
	var RIGHT	= Input.is_action_pressed("ui_right")
	var UP		= Input.is_action_pressed("ui_up")
	var DOWN	= Input.is_action_pressed("ui_down")

	movedir.x = -int(LEFT) + int(RIGHT)
	movedir.y = -int(UP) + int(DOWN)

	# avoid diagonals
	if movedir.x != 0 and movedir.y != 0:
		movedir = Vector2.ZERO

	# if the player is moving
	if movedir != Vector2.ZERO:
		# sets the raycast to the boundaries of the player
		ray.cast_to = movedir * tile_size / 2