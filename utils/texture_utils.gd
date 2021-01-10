"""
A utility to convert a `ViewportTexture` to an `ImageTexture` to make it
independent of the `Viewport`
"""

static func viewport_to_image(viewport_texture : ViewportTexture) -> ImageTexture:
	var image_texture := ImageTexture.new()
	var image := viewport_texture.get_data()
	image.convert(Image.FORMAT_RGBA8)
	image_texture.create_from_image(image)
	return image_texture
