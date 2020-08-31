extends "res://texture_layers/texture_layer.gd"

func _init(_name := "Untitled Bitmap Texture"):
	name = _name
	properties.image_path = ""


func get_properties() -> Array:
	return .get_properties() + [Properties.FilePathProperty.new("image_path")]


func generate_texture() -> void:
	if ResourceLoader.exists(properties.image_path, "Texture"):
		var loaded_texture : Texture = load(properties.image_path)
		var image := loaded_texture.get_data()
		image.resize(int(size.x), int(size.y))
		texture = ImageTexture.new()
		texture.create_from_image(image)
