extends Node2D

signal hovered_over_card
signal hovered_off_card

var hand_position
var card_in_slot

enum CARD_TYPE {
	CRABITAT,
	COMBO,
	ABILITY
}

@export var current_type: CARD_TYPE = CARD_TYPE.CRABITAT

@onready var card_image: Sprite2D = $CardImage

var ability_background = preload("res://Gameplay/Deck/Assets/ability_background.png")
var combo_background = preload("res://Gameplay/Deck/Assets/combo_backround.png")
var crabitat_background = preload("res://Gameplay/Deck/Assets/crabitat_background.png")


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# All cards must be a child of CardMovement or this will error
	get_parent().connect_card_signals(self)
	var new_texture
	match current_type:
		CARD_TYPE.CRABITAT:
			new_texture = crabitat_background
		CARD_TYPE.COMBO:
			new_texture = combo_background
		CARD_TYPE.ABILITY:
			new_texture = ability_background
			
	card_image.texture = new_texture


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func _on_area_2d_mouse_entered() -> void:
	emit_signal("hovered_over_card", self)


func _on_area_2d_mouse_exited() -> void:
	emit_signal("hovered_off_card", self)
