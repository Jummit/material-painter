extends "res://layers/texture_layer.gd"

var cashed_image : ImageTexture
var cashed_path : String

func _init(_name := "Untitled Bitmap Texture").("bitmap"):
	name = _name
	properties.image_path = ""


func get_properties() -> Array:
	return .get_properties() + [Properties.FilePathProperty.new("image_path")]


func _get_as_shader_layer() -> Layer:
	var layer := ._get_as_shader_layer()
	layer.code = "texture({0}, UV).rgb"
	layer.uniform_types = ["sampler2D"]
	
	var image_texture : ImageTexture
	
	if cashed_path == properties.image_path:
		image_texture = cashed_image
	else:
		var image := Image.new()
		image.load(properties.image_path)
		image_texture = ImageTexture.new()
		image_texture.create_from_image(image)
		cashed_image = image_texture
		cashed_path = properties.image_path
	
	layer.uniform_values = [image_texture]
	return layer
