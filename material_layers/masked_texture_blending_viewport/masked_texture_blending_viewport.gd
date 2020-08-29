extends "res://addons/blending/texture_blending_viewport.gd"

func setup_sprite(sprite : Sprite, options : Dictionary) -> void:
	sprite.material = ShaderMaterial.new()
	sprite.material.shader = preload("res://material_layers/masked_texture_blending_viewport/masked_overlay_shader.shader")
	sprite.material.set_shader_param("mask", options.mask)
