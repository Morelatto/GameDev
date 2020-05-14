extends Button


func _ready() -> void:
	pass


func _on_buttontitleplay_pressed() -> void:
	get_tree().change_scene("res://Level.tscn")
