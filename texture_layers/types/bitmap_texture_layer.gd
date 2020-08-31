extends "res://texture_layers/texture_layer.gd"

func _init(_name : String):
	print("initializing")
	name = _name
	properties.image_path = ""


func get_properties() -> Array:
	return .get_properties() + [Properties.FilePathProperty.new("image_path")]


func generate_texture() -> void:
	if ResourceLoader.exists(properties.image_path, "Texture"):
		var image := Image.new()
		if image.load(properties.image_path) == OK:
			image.resize(int(size.x), int(size.y))
			texture = ImageTexture.new()
			texture.create_from_image(image)
