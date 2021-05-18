extends "asset.gd"

const JsonTextureLayer = preload("res://resources/texture/json_texture_layer.gd")

func _init(_path).("layer", _path) -> void:
	pass


func _load_data() -> void:
	data = JsonTextureLayer.new(path)
