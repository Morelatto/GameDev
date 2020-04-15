extends Control

func _ready():
	$Main.slide_in()

func _on_Main_settings_pressed():
	$Main.slide_out()
	$Settings.slide_in()

func _on_Settings_back_button():
	$Settings.slide_out()
	$Main.slide_in()

func _on_Main_play_pressed():
	get_tree().change_scene("res://scenes/Levels/Level1.tscn")
