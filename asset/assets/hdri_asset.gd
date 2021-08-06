extends "asset.gd"

func _init(_path).(_path) -> void:
	pass


static func get_type() -> String:
	return "hdri"


func _load_data() -> void:
	var image := Image.new()
	image.load(path)
	data = image
