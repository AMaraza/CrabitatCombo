extends Control


func _on_play_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Gameplay/Feature/Scenes/GameBoard.tscn")


# Need to create Options menu
#func _on_options_pressed() -> void:
	#get_tree().change_scene_to_file()


func _on_quit_pressed() -> void:
	get_tree().quit()
