extends KinematicBody2D

const GRAVITY = 10
const FLOOR = Vector2(0, -1)

var velocity = Vector2()
var direction = 1
var is_dead = false

export(int) var speed = 30
export(int) var hp = 1
export(Vector2) var size = Vector2.ONE

func _ready():
	scale = size

func dead():
	hp -= 1
	if hp <= 0:
		is_dead = true
		velocity = Vector2.ZERO
		$AnimatedSprite.play("dead")
		$CollisionShape2D.call_deferred("set_disabled", true)
		$Timer.start()
		if scale > Vector2.ONE:
			get_parent().get_node("ScreenShake").screen_shake(1, 10, 100)

func _physics_process(delta):
	if !is_dead:
		velocity.x = speed * direction
		if direction == 1:
			$AnimatedSprite.flip_h = false
		else:
			$AnimatedSprite.flip_h = true
		$AnimatedSprite.play("walk")
		velocity.y += GRAVITY
		velocity = move_and_slide(velocity, FLOOR)

	if is_on_wall():
		direction *= -1
		$RayCast2D.position.x *= -1

	if !$RayCast2D.is_colliding():
		direction *= -1
		$RayCast2D.position.x *= -1

	if get_slide_count() > 0:
		for i in range(get_slide_count()):
			if "Player" in get_slide_collision(i).collider.name:
				get_slide_collision(i).collider.dead()

func _on_Timer_timeout():
	queue_free()
