extends "asset.gd"

const MaterialLayer = preload("res://data/material/material_layer.gd")

func _init(_path).(_path) -> void:
	pass


static func get_type() -> String:
	return "smart_material"


func _load_data() -> void:
	var file := File.new()
	file.open(path, File.READ)
	data = MaterialLayer.new(parse_json(file.get_as_text()))
