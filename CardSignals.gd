extends Node2D

signal hovered_over_card
signal hovered_off_card

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# All cards must be a child of CardMovement or this will error
	get_parent().connect_card_signals(self)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_area_2d_mouse_entered() -> void:
	emit_signal("hovered_over_card", self)


func _on_area_2d_mouse_exited() -> void:
	emit_signal("hovered_off_card", self)
