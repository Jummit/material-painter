static func viewport_to_image(viewport_texture : ViewportTexture) -> ImageTexture:
	var image_texture := ImageTexture.new()
	image_texture.create_from_image(viewport_texture.get_data())
	return image_texture