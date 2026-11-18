extends Node2D

@onready var action_point_icons: Array[CanvasItem] = [$ActionPoint, $ActionPoint2]
@onready var habitat_area = $"../HabitatArea"
@onready var draw_deck = $"../DrawDeck"
@onready var player_hand = $"../PlayerHand"
@onready var card_movement = $"../CardMovement"
@onready var main_discard_slot = $"../DiscardPiles/MainDeckDiscard"
@onready var rule_validator = $"../RuleValidator"


var current_action_points: int = 0
var is_draw_discard_active: bool = false


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Start with full action points matching the number of blue balls assigned
	current_action_points = action_point_icons.size()
	update_action_point_visuals()


# Updates visibility of the blue balls (representing action points) on screen
func update_action_point_visuals() -> void:
	for i in range(action_point_icons.size()):
		if action_point_icons[i]:
			action_point_icons[i].visible = i < current_action_points


# Call this at the start of a player's turn to refill points
func reset_action_points() -> void:
	current_action_points = action_point_icons.size()
	update_action_point_visuals()


# Attempts to spend 1 action point and returns true if successful
func spend_action_point() -> bool:
	if current_action_points > 0:
		current_action_points -= 1
		update_action_point_visuals()
		return true
	return false


func _on_draw_discard_button_pressed() -> void:
	if current_action_points <= 0:
		rule_validator.show_rejection_feedback("Not enough Action Points (Requires 1 AP)!")
		return
	
	is_draw_discard_active = true
	rule_validator.show_rejection_feedback("Draw/Discard mode active: Click Main Deck or drag a card to Discard.")


# Called by DrawDeck or CardMovement when the action is actually performed
func consume_draw_or_discard_action() -> bool:
	if is_draw_discard_active and spend_action_point():
		is_draw_discard_active = false
		return true
	return false


func _on_adopt_crab_button_pressed() -> void:
	# Check if player can complete the action
	var check = rule_validator.can_adopt_crab()
	if not check.valid:
		rule_validator.show_rejection_feedback(check.reason)
		return

	# Find a face-down card in the HabitatArea
	var card_to_flip = find_face_down_aquarium_card()
	
	# Spend the point and flip the card face up
	if spend_action_point():
		is_draw_discard_active = false
		card_to_flip.set_face_down(false)
		print("Adopted crab: ", card_to_flip.card_data.card_name)


# Loops through HabitatArea slots to find the first face-down card
func find_face_down_aquarium_card() -> Node2D:
	if not habitat_area:
		return null
		
	for slot in habitat_area.get_children():
		if "habitat_slot" in slot and slot.habitat_slot and slot.card != null:
			if slot.card.is_face_down:
				return slot.card
	return null


# Defaults to spending 1 point if no number is passed, or spends 'amount' if specified
func spend_multiple_action_points(amount: int) -> bool:
	if current_action_points >= amount:
		current_action_points -= amount
		update_action_point_visuals()
		return true
	return false


func _on_redraw_hand_button_pressed() -> void:
	# Check if player can complete the action
	var check = rule_validator.can_redraw_hand()
	if not check.valid:
		rule_validator.show_rejection_feedback(check.reason)
		return

	# Spend 2 action points and cancel Draw/Discard mode if it was active
	if spend_multiple_action_points(2):
		is_draw_discard_active = false
		discard_entire_hand()
		draw_deck.deal_starting_hand()
		print("Spent 2 Action Points to discard and redraw hand.")


# Moves all cards in PlayerHand to the MainDeckDiscard pile
func discard_entire_hand() -> void:
	# Duplicate the array and clear the hand array immediately so no hand tweens run
	var cards_to_discard = player_hand.player_hand.duplicate()
	player_hand.player_hand.clear()
	
	for card in cards_to_discard:
		if main_discard_slot and card_movement:
			# Move card visually to the discard pile with matching scale and z-index
			card.position = main_discard_slot.position
			card.scale = Vector2(card_movement.CARD_NORMAL_SCALE, card_movement.CARD_NORMAL_SCALE)
			
			card_movement.discard_z_index_tracker += 1
			card.z_index = card_movement.discard_z_index_tracker
			
			# Lock the card so it behaves like a discarded card
			card.card_in_slot = main_discard_slot
			card.get_node("Area2D/CollisionShape2D").disabled = true
		else:
			# queue_free built in and removes a node safely at the end of the frame
			card.queue_free()
