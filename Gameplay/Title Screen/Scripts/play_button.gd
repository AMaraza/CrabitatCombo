extends Button


func _on_pressed() -> void:
	# Connects directly to the gameboard scene need the inbetween scene
	get_tree().change_scene_to_file("res://Gameplay/Feature/Scenes/GameBoard.tscn")
