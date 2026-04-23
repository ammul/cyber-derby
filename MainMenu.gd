class_name MainMenu
extends Control

func _on_start_button_pressed() -> void:
	get_tree().change_scene_to_file(GameConfig.SCENE_RACE_TRACK)
