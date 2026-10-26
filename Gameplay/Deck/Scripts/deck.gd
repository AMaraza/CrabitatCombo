extends Node2D

var card_database
var deck = []
var discard_deck = []
var current_card = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	card_database = preload("res://card_database.gd")
	populate_deck()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_area_2d_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		draw_card()


func populate_deck():
	deck.clear()
	
	var card_pools = [
		card_database.CRABITAT_CARDS,
		card_database.COMBO_CARDS,
		card_database.ABILITY_CARDS
	]
	
	for card_pool in card_pools:
		for card in card_pool:
			for i in range(card_pool[card][0]):
				deck.append(card)
			
	deck.shuffle()
	print(deck)
	
	
func draw_card():
	var max_cards = deck.size()
	
	if current_card < max_cards - 1:
		print(deck[current_card])
		current_card += 1
		discard_deck.append(deck[current_card])
	else:
		print("deck empty")
		current_card = 0
		discard_deck.clear()
		populate_deck()
	
	
