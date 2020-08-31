extends "res://texture_layers/texture_layer.gd"

var painted_image : Image

func _init(_name := "Untitled Paint Texture"):
	name = _name
	painted_image = Image.new()
	painted_image.create(256, 256, false, Image.FORMAT_RGB8)
	painted_image.lock()


func generate_texture() -> void:
	texture = ImageTexture.new()
	texture.create_from_image(painted_image)
