extends Node

@onready var turn_manager = $"../TurnManager"
@onready var action_points = $"../ActionPoints"
@onready var card_movement = $"../CardMovement"
@onready var player_hand = $"../PlayerHand"
@onready var draw_deck = $"../DrawDeck"
@onready var aquarium_deck = $"../AquariumDeck"
@onready var target_selector = get_node_or_null("../CanvasLayer/TargetSelectorPanel")
@onready var feedback_label: Label = get_node_or_null("../CanvasLayer/FeedbackLabel")

var feedback_tween: Tween

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if feedback_label:
		feedback_label.visible = false


# Displays an on-screen banner explaining why an action was rejected
func show_rejection_feedback(reason: String, duration: float = 4.0) -> void:
	print("Action Rejected: ", reason)
	if not feedback_label:
		return
	
	if feedback_tween and feedback_tween.is_running():
		feedback_tween.kill()
	
	feedback_label.text = reason
	feedback_label.visible = true
	feedback_label.modulate.a = 1.0
	
	feedback_tween = create_tween()
	feedback_tween.tween_interval(duration)
	feedback_tween.tween_property(feedback_label, "modulate:a", 0.0, 0.3)
	feedback_tween.tween_callback(func(): feedback_label.visible = false)


# Helper to block actions when it isn't the player's turn or a popup is open
func _check_base_turn_state() -> Dictionary:
	if turn_manager and not turn_manager.is_player_turn():
		return { "valid": false, "reason": "Wait for your turn!"}
	if target_selector and target_selector.visible:
		return { "valid": false, "reason": "Select a target or click Cancel first!" }
	return { "valid": true, "reason": "" } # Complete action no message


# VALIDATE DROPPING A CARD ONTO A SLOT
func can_drop_card_on_slot(card: Node2D, slot: Node2D) -> Dictionary:
	var base = _check_base_turn_state()
	if not base.valid:
		return base
	
	# Dropped outside any slot, silent snapback
	if slot == null:
		return {"valid": false, "reason": "" } # Complete action no message
	
	var data = card.card_data
	if data == null:
		return {"valid": false, "reason": "Invalid card data." }
	
	# Check card-specific custom restrictions
	if data.has_method("validate_custom_rules"):
		var custom = data.validate_custom_rules({ "slot": slot, "turn_manager": turn_manager })
		if not custom.valid:
			return custom
	
	# Case A: Discarding to Main Discard Pile
	if slot.main_discard:
		var is_ability = (data.card_type == CardData.CardType.ABILITY_CARD)
		if is_ability:
			# ---- SOLO PLAY TESTING SCRIPT -------------------
			# Allow playing for solo mode with opponents empty
			return { "valid": true, "reason": "" } # Complete action no message
			# --- REGULAR PLAY SCRIPTING -------------------
			# Single-target abilities require at least 1 active opponent
			#if not data.targets_all_players and turn_manager and turn_manager.get_active_opponents().is_empty():
				#return { "valid": false, "reason": "No valid opponents available to target!" }
			#return { "valid": true, "reason": "" } # Complete action no message
		
		# Non-ability cards require Draw/Discard mode
		if action_points and action_points.current_action_points >= 1:
			return { "valid": true, "reason": "" } # Complete action no message
		return { "valid": false, "reason": "Press Draw/Discard first (Requires 1 Action Point)!" }
	
	# Case B: Restricted Zones (Habitat or Aquarium slots)
	if slot.habitat_slot or slot.aquarium_slot:
		return { "valid": false, "reason": "You cannot manually place cards in the Habitat area!" }
	
	# Case C: Normal Playing Field Slot
	if slot.card_in_slot:
		return { "valid": false, "reason": "That playing slot is already occupied!" }
	
	if data.card_type == CardData.CardType.COMBO_CARD:
		return {"valid": false, "reason": "Click a Combo Card in your hand when its matching cards are on the field!"}
	
	if data.card_type == CardData.CardType.ABILITY_CARD or data.card_type == CardData.CardType.TRAP_CARD:
		return { "valid": false, "reason": "Ability and Trap cards must be placed in the discard pile to activate!" }
	
	# Combo Card requirement: needs at least 2 matching Crabitat cards on the field
	if data.card_type == CardData.CardType.COMBO_CARD:
		var match_count = 0
		for field_slot in card_movement.card_slots:
			if field_slot.card != null and field_slot.card.card_data.card_type == CardData.CardType.CRABITAT_CARD:
				# Check if this field card matches ANY of the valid allowed requirements
				for assoc in data.associated_crabitat_cards:
					if field_slot.card.card_data.card_name == assoc.card_name:
						match_count += 1
						break
		if match_count < 2:
			return { "valid": false, "reason": "Combo requires at least 2 matching Crabitat cards on the field!" }
	
	return { "valid": true, "reason": "" } # Complete action no message


# VALIDATE DRAWING FROM MAIN DECK
func can_draw_main_deck() -> Dictionary:
	var base = _check_base_turn_state()
	if not base.valid:
		return base
	
	if draw_deck and draw_deck.playing_deck.is_empty():
		return { "valid": false, "reason": "The Main Deck is empty!" }
	
	if not action_points or action_points.current_action_points < 1:
		return { "valid": false, "reason": "Press Draw/Discard first (Requires 1 Action Point)!" }
		
	return { "valid": true, "reason": "" } # Complete action no message


# VALIDATE DRAWING FROM AQUARIUM DECK
func can_draw_aquarium_deck() -> Dictionary:
	var base = _check_base_turn_state()
	if not base.valid:
		return base
	
	if aquarium_deck.find_empty_habitat_slot() == null:
		return { "valid": false, "reason": "All Habitat slots are full!" }
	
	if aquarium_deck.get_unused_combo_card_on_field() == null:
		return { "valid": false, "reason": "Must have an unused Combo card on the playing field to draw an Aquarium card!" }
	
	return { "valid": true, "reason": "" } # Complete action no message


# VALIDATE ADOPTING (FLIPPING) AN AQUARIUM CARD
func can_adopt_crab() -> Dictionary:
	var base = _check_base_turn_state()
	if not base.valid:
		return base
	
	if not action_points or action_points.current_action_points < 1:
		return { "valid": false, "reason": "Not enough Action Points (Requires 1)!" }
	
	if action_points.find_face_down_aquarium_card() == null:
		return { "valid": false, "reason": "No face-down Aquarium cards in the Habitat area!" }
	
	return { "valid": true, "reason": "" } # Complete action no message


# VALIDATE REDRAWING HAND
func can_redraw_hand() -> Dictionary:
	var base = _check_base_turn_state()
	if not base.valid:
		return base
	
	if not action_points or action_points.current_action_points < 2:
		return { "valid": false, "reason": "Not enough Action Points (Requires 2)!" }
	
	if player_hand and player_hand.player_hand.is_empty():
		return { "valid": false, "reason": "Your hand is empty! You must have at least 1 card in hand to redraw!" }
	
	return { "valid": true, "reason": "" } # Complete action no message
