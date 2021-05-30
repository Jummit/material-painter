extends "asset.gd"

const JsonTextureLayer = preload("res://material/texture_layer/json_texture_layer.gd")

func _init(_path).(_path) -> void:
	pass


func _load_data() -> void:
	data = JsonTextureLayer.new()
	(data as JsonTextureLayer).file = path


static func get_type() -> String:
	return "layer"
