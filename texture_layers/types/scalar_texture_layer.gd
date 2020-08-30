extends "res://texture_layers/texture_layer.gd"

func _init(_name : String):
	name = _name
	properties.value = .5


func get_properties() -> Array:
	return .get_properties() + [Properties.FloatProperty.new("value", 0.0, 1.0)]


func generate_texture():
	var image := Image.new()
	image.create(1028, 1028, false, Image.FORMAT_RGB8)
	image.fill(Color.black.lightened(properties.value))
	texture = ImageTexture.new()
	texture.create_from_image(image)
