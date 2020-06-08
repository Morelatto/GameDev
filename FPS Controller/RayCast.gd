extends RayCast

func _process(delta: float) -> void:
	if is_colliding():
		print(get_collider().name)
