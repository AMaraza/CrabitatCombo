extends Node2D

var card_database
var deck = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	card_database = preload("res://card_database.gd")
	populate_deck()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_area_2d_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		print("Clicked")


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
