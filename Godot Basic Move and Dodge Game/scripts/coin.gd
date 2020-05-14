extends Area

signal coinCollected

func _ready() -> void:
	pass


func _physics_process(delta: float) -> void:
	rotate_y(deg2rad(3))


func _on_coin_body_entered(body: Node) -> void:
	if body.name == "Steve":
		$AnimationPlayer.play("bounce")
		$Timer.start()


func _on_Timer_timeout() -> void:
	emit_signal("coinCollected")
	queue_free()
