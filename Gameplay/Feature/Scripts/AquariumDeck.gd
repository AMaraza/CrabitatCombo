extends Node2D

const CARD_SCENE_PATH = "res://Gameplay/Feature/Scenes/Card.tscn"
const CARD_DATABASE_PATH = "res://card_database.gd"
const CARD_DRAW_SPEED = 0.3
const DECK_POSITION = [1325, 700]

var card_database
var discard_deck = []
var current_card = 0
var playing_deck = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	card_database = preload(CARD_DATABASE_PATH)
	populate_deck()
	
	# Use deferred call to give other modes (like PlayerHand) a fram to initialize
	# their sizes and variables before drawing cards.
	deal_starting_hermit.call_deferred()


func deal_starting_hermit():
	var starting_hermit_crab_size = 1
	
	for i in range(starting_hermit_crab_size):
		# Wait so that dealing can be seen better
		await get_tree().create_timer(0.15).timeout
		
		# Find the first Hermit Crab card inside the playing deck
		var starting_hermit = null
		for card in playing_deck:
			if card is HermitCardData:
				starting_hermit = card
				break # Found one, stop searching
		
		# Enforce a safety check so it stops looping if the deck runs dry
		if playing_deck.size() > 0:
			draw_card(starting_hermit)
		else:
			print("Stopped dealing: Deck ran ouf of cards during setup!")
			break


func populate_deck():
	playing_deck.clear()
	
	var card_pools = [
		card_database.AQUARIUM_CARDS,
		card_database.HERMIT_CRABS
	]
	
	for card_pool in card_pools:
		for card in card_pool:
			for i in range(card.number_in_deck):
				playing_deck.append(card)
			
	playing_deck.shuffle()


func draw_card(card_drawn = null):
	# If no slots are available, stop immediately
	var target_slot = find_empty_habitat_slot()
	if target_slot == null:
		print("Cannot draw: All habitat slots are full!")
		return # Exit the function completely and nothing happens
		
	# Check to make sure the deck itself isn't empty
	if playing_deck.size() == 0:
		print("Cannot draw: Aquarium deck empty")
		return # Exit the function completely and nothing happens
		
	# If no specific card was passed, default to drawing the top card
	if card_drawn == null:
		card_drawn = playing_deck[0]
	
	# Proceed with drawing since it is verified that a slot is open
	playing_deck.erase(card_drawn)
	
	# --- SAFE ACCESS CARD TYPE AND NUMBER ---
	var type_name = "HERMIT_CRAB"
	if card_drawn is HermitCardData:
		print("Successfully drew card: ", card_drawn.card_name, " | Type: ", type_name, 
	 " | Hermit Crab Order Number: ", card_drawn.order_numer)
	# -----------------------------
	
	# If last card drawn from the deck, disable deck
	if playing_deck.size() == 0:
		$Area2D/CollisionShape2D.disabled = true
		$DrawDeckImage.visible = false
	
	# Instantiate visual card representation
	var card_scene = preload(CARD_SCENE_PATH)
	var new_card = card_scene.instantiate()
	new_card.card_data = card_drawn
	
	# Draw from the deck location set at the const DECK_POSITION
	new_card.global_position = Vector2(DECK_POSITION[0], DECK_POSITION[1])
	
	# Use the image from the card JUST drawn
	new_card.card_image.texture = card_drawn.card_image

	$"../CardMovement".add_child(new_card)
	new_card.name = "Card"
	
	# --- ROUTING LOGIC TO HABITAT SLOT ---
	# Lock the slot and lock the card into position
	target_slot.card_in_slot = true
	new_card.card_in_slot = target_slot
	
	# Animate/snap the card directly to the slot position
	var tween = get_tree().create_tween()
	# Match the field scale used when card is placed
	var field_scale = $"../CardMovement".PLAYING_FIELD_SCALE
	
	tween.parallel().tween_property(new_card, "position", target_slot.position, CARD_DRAW_SPEED)
	tween.parallel().tween_property(new_card, "scale", Vector2(field_scale, field_scale), CARD_DRAW_SPEED)

	# Turn off card collision so it acts like a placed card
	new_card.get_node("Area2D/CollisionShape2D").disabled = true


func find_empty_habitat_slot():
	# Loop through its children to find a matching empty habitat slot
	for slot in $"../HabitatArea".get_children():
		# Checks if slot has a variable called "habitat_slot" in it, 
		# that it is habitat slot, and no card is already assigned
		if "habitat_slot" in slot and slot.habitat_slot and not slot.card_in_slot:
			return slot
	return null
