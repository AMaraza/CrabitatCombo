extends Node2D

signal turn_changed(is_player_turn: bool)

enum TurnOwner { PLAYER, BOT}
var current_turn: TurnOwner = TurnOwner.PLAYER
var active_opponents: Array[String] = ["Bot 1", "Bot 2", "Bot 3"]

@onready var action_points = $"../ActionPoints"
@onready var end_turn_button = $"../EndTurnButton"
@onready var adopt_crab_button = $"../AdoptCrabButton"
@onready var draw_discard_button = $"../DrawDiscardButton"
@onready var redraw_hand_button = $"../RedrawHandButton"

# Reference for popup
@onready var turn_popup_label: Label = $"../CanvasLayer/TurnPopupLabel"
var popup_tween: Tween

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if turn_popup_label:
		turn_popup_label.visible = false
	start_player_turn()


# Displays a temporary banner message on screen with a smooth fade
func show_turn_popup(message: String, duration: float = 1.5) -> void:
	if not turn_popup_label:
		print(message)
		return
	
	# Cancel any previous popup animation still running
	if popup_tween and popup_tween.is_running():
		popup_tween.kill()
	
	turn_popup_label.text = message
	turn_popup_label.visible = true
	turn_popup_label.modulate.a = 0.0
	
	popup_tween = create_tween()
	# Fade in over 0.2 seconds
	popup_tween.tween_property(turn_popup_label, "modulate:a", 1.0, 0.2)
	# Stay visible on screen
	popup_tween.tween_interval(duration)
	# Fade out over 0.3 seconds
	popup_tween.tween_property(turn_popup_label, "modulate:a", 0.0, 0.3)
	# Hide node completely when finished
	popup_tween.tween_callback(func(): turn_popup_label.visible = false)



# Starts the player's turn, unlocks controls, and refills action points
func start_player_turn() -> void:
	current_turn = TurnOwner.PLAYER
	set_player_controls_enabled(true)
	
	if action_points:
		action_points.reset_action_points()
	
	emit_signal("turn_changed", true)
	show_turn_popup("PLAYER'S TURN")


func _on_end_turn_button_pressed() -> void:
	# Prevent clicking if it's already not the player's turn
	if current_turn != TurnOwner.PLAYER:
		return
	
	print("Player ended their turn.")
	start_bot_turn()


# Lock player controls and run bot's turn
func start_bot_turn() -> void:
	current_turn = TurnOwner.BOT
	set_player_controls_enabled(false)
	
	# Cancel Draw/Discard mode if the player left it active when ending their turn
	if action_points:
		action_points.is_draw_discard_active = false
	
	emit_signal("turn_changed", false)
	show_turn_popup("BOT'S TURN")
	
	# Simulate bot thinking/taking actions
	await get_tree().create_timer(2.0).timeout
	
	print("Bot finished its turn and passed back to player.")
	start_player_turn()


# Enables or disables UI buttons during opponent turns
func set_player_controls_enabled(enabled: bool) -> void:
	if end_turn_button:
		end_turn_button.disabled = not enabled
	if adopt_crab_button:
		adopt_crab_button.disabled = not enabled
	if draw_discard_button:
		draw_discard_button.disabled = not enabled
	if redraw_hand_button:
		redraw_hand_button.disabled = not enabled


# Helper function for other scripts to check before allowing clicks or drags
func is_player_turn() -> bool:
	return current_turn == TurnOwner.PLAYER


# Helper function to return the current list of opponents
func get_active_opponents() -> Array[String]:
	return active_opponents


# Optional helper if an opponent gets eliminated or leaves later in the game
func remove_opponent(opponent_name: String) -> void:
	active_opponents.erase(opponent_name)
