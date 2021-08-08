extends Button

"""
A `Button` to select an asset to be used in a `PropertyPanel`

Clicking opens a mini shelf, right-clicking clears the asset.
"""

signal changed
signal minishelf_opened

var value : Asset setget set_value
# warning-ignore:unused_class_variable
var allowed_assets : Array = []

const Asset = preload("res://asset/assets/asset.gd")

func set_value(to : Asset) -> void:
	var changed := value != to
	value = to
	text = "None Selected" if not to else to.name
	if changed:
		emit_signal("changed")


func _gui_input(event : InputEvent) -> void:
	var button_ev := event as InputEventMouseButton
	if button_ev and button_ev.button_index == BUTTON_RIGHT:
		set_value(null)


func _on_pressed() -> void:
	emit_signal("minishelf_opened")
