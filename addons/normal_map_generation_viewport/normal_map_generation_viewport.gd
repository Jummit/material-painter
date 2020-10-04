extends "res://addons/texture_render_viewport/texture_render_viewport.gd"

"""
A `TextureRenderViewport` to generate a normal map from a grayscale heightmap
"""

func get_normal_map(height_map : Texture) -> ViewportTexture:
	var result_size = height_map.get_size()
	var texture_rect := TextureRect.new()
	texture_rect.texture = height_map
	texture_rect.expand = true
	texture_rect.rect_size = result_size
	texture_rect.material = preload("height_to_normal_map.material")
	return render_texture(texture_rect, result_size)
