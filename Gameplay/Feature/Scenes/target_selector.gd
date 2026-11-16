extends PanelContainer

signal target_selected(opponent_name: String, card_data: Resource)
signal selection_canceled

@onready var prompt_label: Label = $VBoxContainer/PromptLabel
@onready var button_container: Container = $VBoxContainer/ButtonContainer
@onready var turn_manager = $"../../TurnManager"
@onready var player_hand = $"../../PlayerHand"
@onready var card_movement = $"../../CardMovement"

var pending_card_node: Node2D = null


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	visible = false


# Open the UI prompt and generate a button for each opponent
func prompt_for_opponent(card_node: Node2D) -> void:
	pending_card_node = card_node
	var card_data = card_node.card_data
	print("Text value: '", card_data.effect_description, "' | Label visible: ", prompt_label.visible, " | Label size: ", prompt_label.size)
	prompt_label.text = card_data.effect_description
	
	# Clear any leftover buttons from a previous prompt
	for child in button_container.get_children():
		child.queue_free()
	
	# Fetch active opponents dynamically from TurnManager
	var opponents: Array[String] = []
	if turn_manager and turn_manager.has_method("get_active_opponents"):
		opponents = turn_manager.get_active_opponents()
	
	# Create a button for each active opponent
	for opponent_name in opponents:
		var btn = Button.new()
		btn.text = opponent_name
		btn.pressed.connect(_on_opponent_button_pressed.bind(opponent_name))
		button_container.add_child(btn)
	
	# Add a Cancel button at the end
	var cancel_btn = Button.new()
	cancel_btn.text = "Cancel"
	cancel_btn.pressed.connect(_on_cancel_button_pressed)
	button_container.add_child(cancel_btn)
	
	visible = true


func _on_opponent_button_pressed(opponent_name: String) -> void:
	visible = false
	
	if pending_card_node and pending_card_node.card_data:
		var card_data = pending_card_node.card_data
		print("Played Ability Card: ", card_data.card_name,
			" | Target: ", opponent_name,
			" | Effect: ", card_data.effect_description)
		emit_signal("target_selected", opponent_name, card_data)
		pending_card_node = null


func _on_cancel_button_pressed() -> void:
	visible = false
	
	if pending_card_node:
		print("Canceled playing Ability Card: ", pending_card_node.card_data.card_name)
		
		# Reset the card's slot tracking and re-enable collision so it can be hovered/dragged again
		pending_card_node.card_in_slot = null
		var col_shape = pending_card_node.get_node_or_null("Area2D/CollisionShape2D")
		if col_shape:
			col_shape.disabled = false
		
		# Adjust discard z-index tracker back down by 1
		if card_movement and card_movement.discard_z_index_tracker > 0:
			card_movement.discard_z_index_tracker -= 1
		
		# Return the card smoothly to the player's hand
		if player_hand and card_movement:
			pending_card_node.z_index = 10
			player_hand.add_card_to_hand(pending_card_node, card_movement.CARD_DEFAULT_SPEED)
			
		pending_card_node = null
		emit_signal("selection_canceled")
