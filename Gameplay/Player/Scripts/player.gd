extends Node2D

#Game Rule Variables Constant
const TURN_ACTIONS: int = 2

#Game Rule Variables Adjustable
var max_hand_size: int = 6
var max_cards_on_table: int = 6

#Game Variables
var cards_in_hand: int = 0
var cards_in_play: int = 0
var combo_cards_in_play: int = 0
var aquarium_cards_in_play: int = 0
var hermit_crab_cards_in_play: int = 0
var matching_hermit_crabs: int = 0
var win_condition_met: bool = false
var turn_actions_spent: int = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
