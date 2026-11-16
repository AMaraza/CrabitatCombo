extends Node2D

var num_players = 3
var players = []
var player_turn = 0

const Player = preload("uid://bfmrpik7558e1")

func _ready() -> void:
	for i in range(num_players):
		var PlayerScript = Player.new()
		players.append(PlayerScript)
		
	
func _process(delta: float) -> void:
	if players[0].cards_in_hand == 6:
		for player in players:
			print(player.cards_in_hand)
			players[0].cards_in_hand += 1
