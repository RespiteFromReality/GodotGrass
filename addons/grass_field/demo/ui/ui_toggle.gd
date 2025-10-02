extends Button

@onready var background: Panel = $"../Background"
@onready var grass: MarginContainer = $"../Grass"

func _on_toggled(toggled_on: bool) -> void:
	background.visible = toggled_on
	grass.visible = toggled_on
