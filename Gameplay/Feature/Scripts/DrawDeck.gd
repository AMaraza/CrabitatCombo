extends Node2D

const CARD_SCENE_PATH = "res://Gameplay/Feature/Scenes/Card.tscn"
const CARD_DRAW_SPEED = 0.3

var playing_deck = ["Ability", "Ability", "Ability"]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


func draw_card():
	var card_drawn = playing_deck[0]
	playing_deck.erase(card_drawn)
	
	# If last card drawn from the deck, disable deck
	if playing_deck.size() == 0:
		$Area2D/CollisionShape2D.disabled = true
		$DrawDeckImage.visible = false
	
	var card_scene = preload(CARD_SCENE_PATH)
	var new_card =card_scene.instantiate()
	$"../CardMovement".add_child(new_card)
	new_card.name = "Card"
	$"../PlayerHand".add_card_to_hand(new_card, CARD_DRAW_SPEED)
