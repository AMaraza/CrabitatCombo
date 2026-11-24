extends ColorRect

@onready var panel: PanelContainer = $CenterContainer/GameOverPanel
@onready var result_label: Label = $CenterContainer/GameOverPanel/VBoxContainer/ResultLabel
@onready var play_again_button: Button = $CenterContainer/GameOverPanel/VBoxContainer/ButtonContainer/PlayAgainButton
@onready var quit_button: Button = $CenterContainer/GameOverPanel/VBoxContainer/ButtonContainer/QuitButton


func _ready() -> void:
	visible = false
	play_again_button.pressed.connect(_on_play_again_pressed)
	quit_button.pressed.connect(_on_quit_pressed)


# Call this when the game finishes to show the win message and options
func show_game_over(message: String) -> void:
	if result_label:
		result_label.text = message
	
	# Smooth fade-in over the playing area
	modulate.a = 0.0
	visible = true
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.25)


func _on_play_again_pressed() -> void:
	# Reloads the current game scene cleanly from the beginning
	get_tree().reload_current_scene()


func _on_quit_pressed() -> void:
	# Exits the game application
	get_tree().quit()
