extends Actor

export var score := 100

func _ready() -> void:
	set_physics_process(false)
	velocity.x = -speed.x

func _on_StompDetector_body_entered(body: PhysicsBody2D) -> void:
	if body.global_position.y > get_node("StompDetector").global_position.y:
		return
	die()

func _physics_process(delta: float) -> void:
	velocity.y += gravity * delta
	# change direction when hits wall
	if is_on_wall():
		velocity.x *= -1.0
	velocity.y = move_and_slide(velocity, FLOOR_NORMAL).y

func die() -> void:
	get_node("CollisionShape2D").disabled = true	
	queue_free()
	PlayerData.score += score
