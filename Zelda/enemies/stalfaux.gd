extends entity

var movetimer_length = 15
var movetimer = 0

func _init():
	SPEED = 40
	DAMAGE = 0.5

func _ready():
	$anim.play("default")
	movedir = dir.rand()

# Changes to a random direction every 1/4 second
func _physics_process(delta):
	movement_loop()
	damage_loop()
	if movetimer > 0:
		movetimer -= 1
	if movetimer == 0 || is_on_wall():
		movedir = dir.rand()
		movetimer = movetimer_length