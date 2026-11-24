extends Node2D
# Project Settings V-sync disabled for better card to mouse movement
const COLLISION_MASK_CARD = 1
const COLLISION_MASK_CARD_SLOT = 2 # Area2D collision layer and mask set to 2 for CardSlot
const CARD_ENLARGED_SCALE = 1.50
const CARD_NORMAL_SCALE = 0.8
const CARD_DEFAULT_SPEED = 0.1
const PLAYING_FIELD_SCALE = 0.6
const CARD_Y_MOVEMENT = 100


var screen_size
var card_being_dragged
var is_hovering_on_card
var player_hand_reference
var original_y_position: float
var discard_z_index_tracker: int = 0
var card_type
var field_center_x: float = 0.0
var field_slot_spacing: float = 180.0 # Fallback spacing if only 1 slot exists

@export var card_slots: Array[Node2D]
@onready var target_selector = $"../CanvasLayer/TargetSelectorPanel"
@onready var rule_validator = $"../RuleValidator"


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	screen_size = get_viewport_rect().size
	player_hand_reference = $"../PlayerHand"
	$"../InputManager".connect("left_mouse_button_released", on_left_click_released)
	
	# Measure the initial center and spacing of the playing field slots
	initialize_field_layout()


func initialize_field_layout() -> void:
	var active_field_slots: Array[Node2D] = get_active_playing_field_slots()
	if active_field_slots.is_empty():
		return
		
	# Sort left-to-right by X position
	active_field_slots.sort_custom(func(a, b): return a.position.x < b.position.x)
	
	var first_x = active_field_slots[0].position.x
	var last_x = active_field_slots[active_field_slots.size() - 1].position.x
	field_center_x = (first_x + last_x) / 2.0
	
	if active_field_slots.size() > 1:
		field_slot_spacing = (last_x - first_x) / float(active_field_slots.size() - 1)


# Returns only valid, visible playing-field slots (excluding discard, habitat, or aquarium slots)
func get_active_playing_field_slots() -> Array[Node2D]:
	var field_slots: Array[Node2D] = []
	for slot in card_slots:
		if is_instance_valid(slot) and slot.visible:
			if not slot.main_discard and not slot.habitat_slot and not slot.aquarium_slot:
				field_slots.append(slot)
	return field_slots


# Called every frame. 'delta' is the elapsed time since the previous frame.
# use _delta instead of delta if delta isn't used in code per debugger message
func _process(_delta: float) -> void:
	# This will keept the card from being dragged off screen
	if card_being_dragged:
		var mouse_pos = get_global_mouse_position()
		card_being_dragged.position = Vector2(clamp(mouse_pos.x, 0, screen_size.x),
			clamp(mouse_pos.y, 0, screen_size.y))


func start_drag(card):
	# Clear highlight if player drags the card (e.g. to discard)
	set_combo_highlight(card, false)
	card_being_dragged = card
	is_hovering_on_card = false
	card_type = card.card_data.card_type
	card.scale = Vector2(CARD_NORMAL_SCALE, CARD_NORMAL_SCALE)
	card.z_index = 1000 # Keep card on top while dragging

# Need to add difference between discard slot, habitat slot, playing area slot
func finish_drag():
	var card_slot_found = raycast_check_for_card_slot()
	var check = rule_validator.can_drop_card_on_slot(card_being_dragged, card_slot_found)
	# If cannot be dragged to location, call popup message based on location
	if not check.valid:
		if check.reason != "":
			rule_validator.show_rejection_feedback(check.reason)
			flash_card_rejected(card_being_dragged)
		
		player_hand_reference.add_card_to_hand(card_being_dragged, CARD_DEFAULT_SPEED)
		card_being_dragged.z_index = 10
		card_being_dragged = null
		return
	
	# --- VALID DROP: Proceed with state changes ---
	if card_slot_found.main_discard:
		if card_type != CardData.CardType.ABILITY_CARD:
			$"../ActionPoints".consume_draw_or_discard_action()
		
		card_being_dragged.scale = Vector2(CARD_NORMAL_SCALE, CARD_NORMAL_SCALE)
		discard_z_index_tracker += 1
		card_being_dragged.z_index = discard_z_index_tracker
		card_slot_found.card_in_slot = false
		slot_card(card_slot_found)
	else:
		card_being_dragged.scale = Vector2(PLAYING_FIELD_SCALE, PLAYING_FIELD_SCALE)
		card_slot_found.card_in_slot = true
		card_being_dragged.z_index = 5
		slot_card(card_slot_found)
		
	card_being_dragged = null


# Visual red flash when a card placement is rejected
func flash_card_rejected(card: Node2D) -> void:
	var tween = create_tween()
	card.modulate = Color(1.0, 0.35, 0.35)
	tween.tween_property(card, "modulate", Color.WHITE, 0.25)


# Removes card from hand and slots into position
func slot_card(card_slot_found):
	var dragged_card_data = card_being_dragged.card_data
	
	# Section for opponent selection for ability cards
	if card_slot_found.main_discard and dragged_card_data.card_type == CardData.CardType.ABILITY_CARD:
		if dragged_card_data.targets_all_players:
			print("Played Global Ability Card: ", dragged_card_data.card_name,
				" | Effect: ", dragged_card_data.effect_description)
		else:
			if target_selector:
				# Pass the physical card node so Cancel can return it to hand
				target_selector.prompt_for_opponent(card_being_dragged)

	# --- BYPASS COMBO VALIDATION IF DISCARDING ---
	if not card_slot_found.main_discard and dragged_card_data.card_type == 1:
		var crabitat_slots_to_clear = []
		
		# Gather all Type 0 (CRABITAT_CARD) cards currently on the field
		for slot in card_slots:
			if slot.card != null and slot.card.card_data.card_type == 0:
				# Check if this field card matches ANY of the valid allowed requirements
				for assoc_card in dragged_card_data.associated_crabitat_cards:
					if slot.card.card_data.card_name == assoc_card.card_name:
						crabitat_slots_to_clear.append(slot)
						print("MMatched combo piece to clear: ", slot.card.card_data.card_name)
						break # Move to next slot to avoid double counting
		
		# If we don't have at least 2 valid pieces on the field, reject the play
		if crabitat_slots_to_clear.size() < 2:
			# Return the card smoothly back to the hand
			player_hand_reference.add_card_to_hand(card_being_dragged, CARD_DEFAULT_SPEED)
			card_being_dragged.z_index = 10 
			card_slot_found.card_in_slot = false 
			return 
			
		print("Can Play Combo! Clear pieces and shrink playing area slots.")
		
		# SEND MATCHED CRABITAT CARDS TO THE MAIN DISCARD PILE
		for slot in crabitat_slots_to_clear:
			var card_to_discard = slot.card
			
			# Reference main discard slot
			var main_discard_slot = $"../DiscardPiles/MainDeckDiscard" 
			
			if main_discard_slot:
				# Physical movement to discard pile visual position
				card_to_discard.position = main_discard_slot.position
				
				# Match the scale of the discard pile (0.8) instead of field size (0.6)
				card_to_discard.scale = Vector2(CARD_NORMAL_SCALE, CARD_NORMAL_SCALE)
				
				# Increment the counter to render cards cleanly above the previous one
				discard_z_index_tracker += 1
				card_to_discard.z_index = discard_z_index_tracker
				
				# Reset card tracking states
				card_to_discard.card_in_slot = main_discard_slot
				card_to_discard.get_node("Area2D/CollisionShape2D").disabled = true
			else:
				# Fallback fallback if discard slot isn't found: just delete the visual instance
				card_to_discard.queue_free()
				
			# Clear the slot references entirely so they are empty again
			slot.card = null
			slot.card_in_slot = false

	# --- PHYSICAL CARD PLACEMENT (Shared by normal plays, successful combos, & discards) ---
	card_being_dragged.card_in_slot = card_slot_found
	player_hand_reference.remove_card_from_hand(card_being_dragged)
	card_being_dragged.position = card_slot_found.position
	card_slot_found.card = card_being_dragged
	card_being_dragged.get_node("Area2D/CollisionShape2D").disabled = true



func connect_card_signals(card):
	card.connect("hovered_over_card", on_hovered_over_card)
	card.connect("hovered_off_card", on_hovered_off_card)


# Used with signal connection to Input Manager
func on_left_click_released():
	if card_being_dragged:
		finish_drag()


func on_hovered_over_card(card):
	if !is_hovering_on_card:
		is_hovering_on_card = true
		# Original y position updated populated here to avoid card creeping bug
		original_y_position = card.position.y
		highlight_card(card, true)


func on_hovered_off_card(card):
	# Check if card is NOT in a card slot AND NOT being dragged
	if !card.card_in_slot && !card_being_dragged:
		# If not dragging
		highlight_card(card, false)
		# Check if hovered off card and straight on to another card
		var new_card_hovered = raycast_check_for_card()
		if new_card_hovered:
			highlight_card(new_card_hovered, true)
		else:
			is_hovering_on_card = false


# If hovered = true, enlarge card, move up, and normal size if false and move to original position
func highlight_card(card, hovered):
	if hovered:
		card.scale = Vector2(CARD_ENLARGED_SCALE, CARD_ENLARGED_SCALE)
		card.position.y = original_y_position - CARD_Y_MOVEMENT
		card.z_index = 1000
		
		# Highlight matchig field cards if hovering over a Combo Card in hand
		if card.card_in_slot == null and card.card_data.card_type == CardData.CardType.COMBO_CARD:
			set_combo_highlight(card, true)
	else:
		card.scale = Vector2(CARD_NORMAL_SCALE, CARD_NORMAL_SCALE)
		# Use card.hand_position if available instead of current card.position.x
		if card.hand_position != null:
			card.position = card.hand_position
		else:
			card.position = Vector2(card.position.x, original_y_position)
		card.z_index = 10
		
		# Clear field highlights when mouse leaves the card
		set_combo_highlight(card, false)


func raycast_check_for_card_slot():
	var space_state = get_world_2d().direct_space_state
	var parameters = PhysicsPointQueryParameters2D.new()
	parameters.position = get_global_mouse_position()
	parameters.collide_with_areas = true
	parameters.collision_mask = COLLISION_MASK_CARD_SLOT
	var result = space_state.intersect_point(parameters)
	if result.size() > 0:
		return result[0].collider.get_parent()
	return null


func raycast_check_for_card():
	var space_state = get_world_2d().direct_space_state
	var parameters = PhysicsPointQueryParameters2D.new()
	parameters.position = get_global_mouse_position()
	parameters.collide_with_areas = true
	parameters.collision_mask = COLLISION_MASK_CARD
	var result = space_state.intersect_point(parameters)
	if result.size() > 0:
		return get_card_with_highest_z_index(result)
	return null


func get_card_with_highest_z_index(cards):
	# Assume the first card in cards array has the highest z index
	var highest_z_card = cards[0].collider.get_parent()
	var highest_z_index = highest_z_card.z_index
	
	# Loop through the rest of the cards checking for a higher z index
	for i in range(1, cards.size()):
		var current_card = cards[i].collider.get_parent()
		if current_card.z_index > highest_z_index:
			highest_z_card = current_card
			highest_z_index = current_card.z_index
	return highest_z_card


# Find up to 2 matching Crabitat slots on the field for a given Combo card
func get_matching_combo_slots(combo_card: Node2D) -> Array[Node2D]:
	var matched_slots: Array[Node2D] = []
	if not is_instance_valid(combo_card) or combo_card.card_data == null:
		return matched_slots
	
	# --- DEBUG OUTPUT ---
	print("Combo Card: '", combo_card.card_data.card_name, "' | Associated count: ", combo_card.card_data.associated_crabitat_cards.size())
	for req in combo_card.card_data.associated_crabitat_cards:
		print("  -> Needs: '", req.card_name if req else "NULL", "'")
	# --------------------
	
	# Ensure it is a Combo Card (CardType.COMBO_CARD == 1)
	if combo_card.card_data.card_type != CardData.CardType.COMBO_CARD:
		return matched_slots
	
	var req_names: Array[String] = []
	for assoc in combo_card.card_data.associated_crabitat_cards:
		if assoc:
			req_names.append(assoc.card_name)
	print("Required cards for combo: ", req_names)
	print("Total slots in card_slots array: ", card_slots.size())
	
	for slot in card_slots:
		# Safely check that both the slot and the card inside it exist
		if not is_instance_valid(slot) or not is_instance_valid(slot.card):
			continue
		if slot.card.card_data == null:
			continue

		# --- DEBUG OUTPUT ---
		print("  Field Slot [", slot.name, "] holds: '", slot.card.card_data.card_name, "' (type: ", slot.card.card_data.card_type, ")")
		# --------------------
		
		if slot.card.card_data.card_type == CardData.CardType.CRABITAT_CARD:
			for assoc_card in combo_card.card_data.associated_crabitat_cards:
				if assoc_card and slot.card.card_data.card_name == assoc_card.card_name:
					matched_slots.append(slot)
					break
		
		# Stop 2 required pieces have been found
		if matched_slots.size() == 2:
			break
	
	print("Total matches found: ", matched_slots.size())
	return matched_slots


# Highlights or unhighlights matching Crabitat cards on the playing field
func set_combo_highlight(combo_card: Node2D, enable: bool) -> void:
	# Clear existing highlights on all field cards if any
	for slot in card_slots:
		if is_instance_valid(slot) and is_instance_valid(slot.card):
			slot.card.modulate = Color.WHITE
			if slot.card.card_image:
				slot.card.card_image.modulate = Color.WHITE
	
	if not enable or not is_instance_valid(combo_card):
		return
	
	var matched_slots = get_matching_combo_slots(combo_card)
	
	# Only highlight if a full valid combo (2 cards) is available on the field
	if matched_slots.size() >= 2:
		for slot in matched_slots:
			if is_instance_valid(slot) and is_instance_valid(slot.card):
				# Glowing golden-green tint to indicate combo readiness
				slot.card.modulate = Color(0.6, 1.3, 0.6)
				if slot.card.card_image:
					slot.card.card_image.modulate = Color(0.5, 1.5, 0.5)


# Executes the combo: discards the 2 matched cards, 
# removes 1 slot, and places combo card in the remaining slot
func play_combo_card_from_hand(combo_card: Node2D) -> bool:
	var matched_slots = get_matching_combo_slots(combo_card)
	if matched_slots.size() < 2:
		return false
	
	# Clear hover highlight before moving cards
	set_combo_highlight(combo_card, false)
	is_hovering_on_card = false
	
	var target_slot: Node2D = matched_slots[0] # Remaining slot where Combo card will go
	var slot_to_remove: Node2D = matched_slots[1] # Slot removed from playing area
	var main_discard_slot = $"../DiscardPiles/MainDeckDiscard"
	
	# Send both matched Crabitat cards to the Main Discard Pile
	for slot in matched_slots:
		var card_to_discard = slot.card
		if main_discard_slot:
			card_to_discard.position = main_discard_slot.position
			card_to_discard.scale = Vector2(CARD_NORMAL_SCALE, CARD_NORMAL_SCALE)
			discard_z_index_tracker += 1
			card_to_discard.z_index = discard_z_index_tracker
			card_to_discard.card_in_slot = main_discard_slot
			card_to_discard.get_node("Area2D/CollisionShape2D").disabled = true
		else:
			card_to_discard.queue_free()
		
		slot.card = null
		slot.card_in_slot = false
	
	# Remove the second slot from the playing area
	var slot_area = slot_to_remove.get_node_or_null("Area2D")
	if slot_area:
		slot_area.queue_free()
	slot_to_remove.visible = false
	card_slots.erase(slot_to_remove)
	
	# Place the Combo Card into the remaining slot
	player_hand_reference.remove_card_from_hand(combo_card)
	combo_card.card_in_slot = target_slot
	target_slot.card = combo_card
	target_slot.card_in_slot = true
	
	combo_card.position = target_slot.position
	combo_card.scale = Vector2(PLAYING_FIELD_SCALE, PLAYING_FIELD_SCALE)
	combo_card.z_index = 5
	combo_card.get_node("Area2D/CollisionShape2D").disabled = true
	
	# Smoothly bring the remaining slots and their cards together
	recenter_playing_field_slots(0.25)
	
	return true


func recenter_playing_field_slots(duration: float = 0.25) -> void:
	var remaining_slots: Array[Node2D] = get_active_playing_field_slots()
	var count = remaining_slots.size()
	if count == 0:
		return
		
	# Keep slots ordered left-to-right so they don't swap places
	remaining_slots.sort_custom(func(a, b): return a.position.x < b.position.x)
	
	# Calculate the new starting X so the group stays centered on field_center_x
	var total_width = (count - 1) * field_slot_spacing
	var start_x = field_center_x - (total_width / 2.0)
	
	var tween = create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	for i in range(count):
		var slot = remaining_slots[i]
		var target_pos = Vector2(start_x + (i * field_slot_spacing), slot.position.y)
		
		# Tween the slot itself
		tween.tween_property(slot, "position", target_pos, duration)
		
		# Also tween the card currently sitting in that slot (including the newly placed Combo Card)
		if is_instance_valid(slot.card):
			tween.tween_property(slot.card, "position", target_pos, duration)
