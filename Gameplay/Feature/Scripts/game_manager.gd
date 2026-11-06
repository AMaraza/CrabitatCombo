extends Node2D

var num_players = 1
var players = []
var player_turn = 0

const Player = preload("uid://bfmrpik7558e1")

func _ready() -> void:
	for i in range(num_players):
		players.append(Player)
		print(players)
	
func _process(delta: float) -> void:
	pass
