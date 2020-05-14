extends Label

var coins = 0

func _ready() -> void:
	text = String(coins)


func _on_coin_collected() -> void:
	coins += 1
	_ready()
	if coins == 5:
		$Timer.start()


func _on_Timer_timeout() -> void:
	get_tree().change_scene("res://YouWin.tscn")
