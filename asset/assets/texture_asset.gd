extends "asset.gd"

var texture : ImageTexture

func _init(_path).(_path) -> void:
	pass


static func get_type() -> String:
	return "texture"


func _load_data() -> void:
	var image := Image.new()
	image.load(path)
	data = image
	texture = ImageTexture.new()
	texture.create_from_image(image)
