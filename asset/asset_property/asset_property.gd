extends Button

signal changed

var accepted_assets : Array

var value

const Asset = preload("res://asset/assets/asset.gd")

func can_drop_data(_position : Vector2, data) -> bool:
	return data is Asset and data.get_type() in accepted_assets


func drop_data(_position : Vector2, data) -> void:
	value = data
	emit_signal("changed")
