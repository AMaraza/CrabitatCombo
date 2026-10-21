extends Node2D
# Project Settings V-sync disabled for better card to mouse movement
const COLLISION_MASK_CARD = 1
const COLLISION_MASK_CARD_SLOT = 2 # Area2D collision layer and mask set to 2 for CardSlot
const CARD_ENLARGED_SCALE = 1.50
const CARD_NORMAL_SCALE = 0.8
const CARD_DEFAULT_SPEED = 0.1
const PLAYING_FIELD_SCALE = 0.6


var screen_size
var card_being_dragged
var is_hovering_on_card
var player_hand_reference


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	screen_size = get_viewport_rect().size
	player_hand_reference = $"../PlayerHand"
	$"../InputManager".connect("left_mouse_button_released", on_left_click_released)


# Called every frame. 'delta' is the elapsed time since the previous frame.
# use _delta instead of delta if delta isn't used in code per debugger message
func _process(_delta: float) -> void:
	# This will keept the card from being dragged off screen
	if card_being_dragged:
		var mouse_pos = get_global_mouse_position()
		card_being_dragged.position = Vector2(clamp(mouse_pos.x, 0, screen_size.x),
			clamp(mouse_pos.y, 0, screen_size.y))


func start_drag(card):
	card_being_dragged = card
	card.scale = Vector2(CARD_NORMAL_SCALE, CARD_NORMAL_SCALE)


func finish_drag():
	card_being_dragged.scale = Vector2(CARD_ENLARGED_SCALE, CARD_ENLARGED_SCALE)
	var card_slot_found = raycast_check_for_card_slot()
	if card_slot_found and not card_slot_found.card_in_slot:
		# Card dropped in empty card slot & becomes no longer moveable
		card_being_dragged.scale = Vector2(PLAYING_FIELD_SCALE, PLAYING_FIELD_SCALE)
		card_being_dragged.z_index = -1 # stop slotted card rendering over dragged card
		card_being_dragged.card_in_slot = card_slot_found
		player_hand_reference.remove_card_from_hand(card_being_dragged)
		card_being_dragged.position = card_slot_found.position
		card_being_dragged.get_node("Area2D/CollisionShape2D").disabled = true
		card_slot_found.card_in_slot = true
	else:
		player_hand_reference.add_card_to_hand(card_being_dragged, CARD_DEFAULT_SPEED)
	card_being_dragged = null
	


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


# If hovered = true, enlarge card, normal size if false
func highlight_card(card, hovered):
	if hovered:
		card.scale = Vector2(CARD_ENLARGED_SCALE, CARD_ENLARGED_SCALE)
		card.z_index = 2
	else:
		card.scale = Vector2(CARD_NORMAL_SCALE, CARD_NORMAL_SCALE)
		card.z_index = 1


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
	
	
	
