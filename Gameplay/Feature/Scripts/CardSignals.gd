extends Node2D

signal hovered_over_card
signal hovered_off_card

var hand_position
var card_in_slot = null
var card_data: Resource
var is_face_down: bool = false
# Tracks if combo card already gave a draw for aquarium deck
var has_used_combo_draw: bool = false

@export var card_image: Sprite2D
# Reference to Aquarium card back
@export var card_back_texture: Texture2D = preload("res://Gameplay/Feature/Assets/AquariumCardBack.png")


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# All cards must be a child of CardMovement or this will error
	get_parent().connect_card_signals(self)
	update_visuals()


func set_face_down(face_down: bool) -> void:
	is_face_down = face_down
	update_visuals()


func update_visuals() -> void:
	if not card_image:
		return
		
	if is_face_down:
		card_image.texture = card_back_texture
	else:
		card_image.texture = card_data.card_image


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func _on_area_2d_mouse_entered() -> void:
	emit_signal("hovered_over_card", self)


func _on_area_2d_mouse_exited() -> void:
	emit_signal("hovered_off_card", self)
