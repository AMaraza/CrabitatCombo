extends Node2D

const CARD_WIDTH = 160 # Gap size between cards
const HAND_Y_POSITION = 1400 # How far down on screen for playing hand of cards
const CARD_SNAPBACK_SPEED = 0.1

var player_hand = []
var center_screen_x

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	center_screen_x = get_viewport().size.x / 2


func add_card_to_hand(card, speed):
	if card not in player_hand:
		player_hand.insert(0, card)
		update_hand_positions(speed)
	else:
		animate_card_to_position(card, card.hand_position, CARD_SNAPBACK_SPEED)


func update_hand_positions(speed):
	for i in range(player_hand.size()):
		# Get new card position based on index
		var new_position = Vector2(calculate_card_position(i), HAND_Y_POSITION)
		var card = player_hand[i]
		card.hand_position = new_position
		animate_card_to_position(card, new_position, speed)


func calculate_card_position(index):
	var total_width = (player_hand.size() - 1) * CARD_WIDTH
	# Debugger warning error if use 2 instead of 2.0 or cast whole thing to integer
	var x_offset = center_screen_x + index * CARD_WIDTH - total_width / 2.0
	return x_offset


func animate_card_to_position(card, new_position, speed):
	var tween = get_tree().create_tween()
	tween.tween_property(card, "position", new_position, speed)


func remove_card_from_hand(card):
	if card in player_hand:
		player_hand.erase(card)
		update_hand_positions(CARD_SNAPBACK_SPEED)
