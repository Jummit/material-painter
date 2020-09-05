extends "res://addons/blending/texture_blending_viewport.gd"

func _setup_texture(texture_rect : TextureRect, options : Dictionary) -> void:
	texture_rect.material = ShaderMaterial.new()
	texture_rect.material.shader = preload("res://material_layers/masked_texture_blending_viewport/masked_overlay_shader.shader")
	texture_rect.material.set_shader_param("mask", options.mask)
