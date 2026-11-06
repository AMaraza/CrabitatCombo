extends Node2D

const CARD_SCENE_PATH = "res://Gameplay/Feature/Scenes/Card.tscn"
const CARD_DATABASE_PATH = "res://card_database.gd"
const CARD_DRAW_SPEED = 0.3
const DECK_POSITION = [1325, 700]

var card_database
var discard_deck = []
var current_card = 0
var playing_deck = []

# Tracks if we are still dealing the setup card
var is_initial_deal: bool = true

# Reference to the CardMovement script to access the shared 'card_slots' array
@onready var card_movement = $"../CardMovement"

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
			# The initial setup card is drawn face up (face_down = false)
			draw_card(starting_hermit, false)
		else:
			print("Stopped dealing: Deck ran ouf of cards during setup!")
			break
	
	# Initial setup is complete. Any future clicks draw face down.
	is_initial_deal = false


func populate_deck():
	playing_deck.clear()
	
	var card_pools = [
		card_database.HERMIT_CRABS
	]
	
	for card_pool in card_pools:
		for card in card_pool:
			for i in range(card.number_in_deck):
				playing_deck.append(card)
			
	playing_deck.shuffle()


func draw_card(card_drawn = null, face_down: bool = true):
	# --- VALIDATE COMBO CONDITION IF CLICKED MANUALLY ---
	if not is_initial_deal:
		# Find an available combo card instance that hasn't been used yet
		var valid_combo_card = get_unused_combo_card_on_field()
		
		if valid_combo_card == null:
			print("Cannot draw: No unused combo card is currently slotted in the playing area!")
			return # Exit early, nothing happens
		else:
			# Mark this specific card as used before proceeding with the draw
			valid_combo_card.has_used_combo_draw = true
			print("Combo draw claimed using card: ", valid_combo_card.card_data.card_name)
	
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
	
	# Apply visibility rule right away before moving the card
	new_card.set_face_down(face_down)
	
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


# Returns the physical Card node if an unused combo exists, otherwise returns null
func get_unused_combo_card_on_field() -> Node2D:
	if card_movement and card_movement.card_slots:
		for slot in card_movement.card_slots:
			if slot.card != null and "card_data" in slot.card and slot.card.card_data:
				# CardType.COMBO_CARD is index 1, and check our new instance flag
				if slot.card.card_data.card_type == 1 and not slot.card.has_used_combo_draw:
					return slot.card # Return the actual Card instance node
	return null


# Triggered whenever the user clicks on the physical deck Area2D
func _on_deck_clicked():
	# Since setup is over, is_initial_deal is false, drawing face down automatically
	draw_card(null, !is_initial_deal)
