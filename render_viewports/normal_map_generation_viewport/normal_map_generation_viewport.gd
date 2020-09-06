extends "res://addons/texture_render_viewport/texture_render_viewport.gd"

"""
A `Viewport` to generate a normal map from a grayscale heightmap
"""

func get_normal_map(height_map : ImageTexture) -> ImageTexture:
	var result_size = height_map.get_size()
	var texture_rect := TextureRect.new()
	texture_rect.texture = height_map
	texture_rect.expand = true
	texture_rect.rect_size = result_size
	texture_rect.material = preload("res://render_viewports/normal_map_generation_viewport/height_to_normal_map.material")
	return render_texture(texture_rect, result_size)
