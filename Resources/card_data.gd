extends Resource

class_name CardData

enum CardType {
	CRABITAT_CARD,
	COMBO_CARD,
	ABILITY_CARD,
	TRAP_CARD,
	AQUARIUM_CARD
}

@export var card_name: String
@export var number_in_deck: int
@export var actions_to_play: int
@export var card_image: Texture2D
@export var card_type: CardType
@export var associated_crabitat_cards: Array[CardData]
@export var targets_all_players: bool = false
@export var effect_description: String
