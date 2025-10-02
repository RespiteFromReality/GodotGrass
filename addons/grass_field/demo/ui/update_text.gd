extends HSlider

@onready var label: Label = $Label

func _ready() -> void:
	label.text = str('%.2f' % value)

func _on_value_changed(value: float) -> void:
	label.text = str('%.2f' % value)
