extends OptionButton

signal map_selected(map)

const Constants = preload("res://main/constants.gd")

func _ready() -> void:
	for map in Constants.TEXTURE_MAP_TYPES:
		add_item(map)


func _on_item_selected(index : int) -> void:
	emit_signal("map_selected", Constants.TEXTURE_MAP_TYPES[index])
