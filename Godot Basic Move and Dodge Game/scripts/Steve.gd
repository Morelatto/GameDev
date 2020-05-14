extends KinematicBody

const SPEED = 12
const ROT_SPEED = 9

var velocity = Vector3.ZERO

func _physics_process(delta):
	if Input.is_action_pressed("ui_right") and Input.is_action_pressed("ui_left"):
		velocity.x = 0
	elif Input.is_action_pressed("ui_right"):
		velocity.x = SPEED
		$MeshInstance.rotate_z(deg2rad(-ROT_SPEED))
	elif Input.is_action_pressed("ui_left"):
		velocity.x = -SPEED
		$MeshInstance.rotate_z(deg2rad(ROT_SPEED))
	else:
		velocity.x = lerp(velocity.x, 0, 0.1)

	if Input.is_action_pressed("ui_up") and Input.is_action_pressed("ui_down"):
		velocity.z = 0
	elif Input.is_action_pressed("ui_up"):
		velocity.z = -SPEED
		$MeshInstance.rotate_x(deg2rad(-ROT_SPEED))
	elif Input.is_action_pressed("ui_down"):
		velocity.z = SPEED
		$MeshInstance.rotate_x(deg2rad(ROT_SPEED))
	else:
		velocity.z = lerp(velocity.z, 0, 0.1)

	move_and_slide(velocity)


func _on_enemy_body_entered(body: Node) -> void:
	if body.name == "Steve":
		get_tree().change_scene("res://GameOver.tscn")


func _on_coin_body_entered(body: Node) -> void:
	pass # Replace with function body.
