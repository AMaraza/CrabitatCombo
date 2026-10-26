extends Node2D

const CARD_SCENE_PATH = "res://Gameplay/Feature/Scenes/Card.tscn"
const CARD_DATABASE_PATH = "res://card_database.gd"
const CARD_DRAW_SPEED = 0.3

var card_database
var discard_deck = []
var current_card = 0
var playing_deck = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	card_database = preload(CARD_DATABASE_PATH)
	populate_deck()


func populate_deck():
	playing_deck.clear()
	
	for i in range(card_database.PLAY_SAND_RESOURCE.number_in_deck):
		playing_deck.append(card_database.PLAY_SAND_RESOURCE)
		print(playing_deck)
			
	playing_deck.shuffle()


func draw_card():
	var card_drawn = playing_deck[0]
	playing_deck.erase(card_drawn)
	
	# If last card drawn from the deck, disable deck
	if playing_deck.size() == 0:
		$Area2D/CollisionShape2D.disabled = true
		$DrawDeckImage.visible = false
	
	var card_scene = preload(CARD_SCENE_PATH)
	var new_card = card_scene.instantiate()
	new_card.card_image.texture = playing_deck[0].card_image

	$"../CardMovement".add_child(new_card)
	new_card.name = "Card"
	$"../PlayerHand".add_card_to_hand(new_card, CARD_DRAW_SPEED)
	
	var max_cards = playing_deck.size()
	
	if current_card < max_cards - 1:
		print(playing_deck[current_card])
		current_card += 1
		discard_deck.append(playing_deck[current_card])
	else:
		print("deck empty")
		current_card = 0
