#CARD TYPES: 0 = Crabitat, 1 = Combo, 2 = Ability, 3 = Trap, 4 = Aquarium, 5 = Hermit Crab

const CRABITAT_CARDS = {
	#[Number in Deck, Actions Taken, Card Type, Card Description, Associated Combo]
	"Play Sand": [2, 0, preload("res://Gameplay/Deck/Assets/PlaySand.png"), "Part of Substrate Combo", "Substrate"],
	"Coconut Fiber": [2, 0, preload("res://Gameplay/Deck/Assets/CoconutFiber.png"), "Part of Substrate Combo", "Substrate"],
	"Crab Food": [2, 0, preload("res://Gameplay/Deck/Assets/CrabFood.png"), "Part of Balanced Diet Combo", "Balanced Diet"],
	"Food Bowl": [2, 0, preload("res://Gameplay/Deck/Assets/FoodBowl.png"), "Part of Balanced Diet Combo", "Balanced Diet"],
}

const COMBO_CARDS = {
	#[Number in Deck, Actions Taken]
	"Substrate": [2, 0, preload("res://Gameplay/Deck/Assets/Substrate.png")],
	"Balanced Diet": [2, 0, preload("res://Gameplay/Deck/Assets/BalancedDiet.png")]
}

const ABILITY_CARDS = {
	#[Number in Deck, Actions Taken, Description]
	"Molting": [2, 0, preload("res://Gameplay/Deck/Assets/Molting.png"), "Skip an Opponent's Turn"]
}

const AQUARIUM_CARDS = {
	#[Number in Deck, Actions Taken]
	"Aquarium Card": [4, 1, 4]
}

const HERMIT_CRABS = {
	#[Number in Deck, Actions Taken]
	"Purple Pincher": [4, 1, 5]
}
