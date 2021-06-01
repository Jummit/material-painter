extends Button

signal changed

var value : Asset setget set_value

const Asset = preload("res://asset/assets/asset.gd")

func set_value(to : Asset) -> void:
	if value != to:
		emit_signal("changed")
	value = to
	text = "None Selected" if not to else to.name
