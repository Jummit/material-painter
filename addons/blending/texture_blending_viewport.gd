extends Viewport

const TextureUtils = preload("res://utils/texture_utils.gd")

func blend(textures : Array, blend_modes : PoolStringArray, opacity_values : PoolRealArray, default_blend_mode := "normal", default_opacity := 1.0) -> ImageTexture:
	for back_buffer in get_children():
		back_buffer.free()
	
	for layer in textures.size():
		var texture : Texture = textures[layer]
		var blend_mode : String = default_blend_mode if blend_modes.size() <= layer else blend_modes[layer]
		var opacity : float = default_opacity if opacity_values.size() <= layer else opacity_values[layer]
		
		var back_buffer := BackBufferCopy.new()
		back_buffer.copy_mode = BackBufferCopy.COPY_MODE_VIEWPORT
		add_child(back_buffer)
		
		var sprite := Sprite.new()
		sprite.texture = texture
		sprite.centered = false
		sprite.material = ShaderMaterial.new()
		sprite.material.shader = load("res://addons/blending/blend_shaders/%s.shader" % blend_mode)
		sprite.material.set_shader_param("value", opacity)
		back_buffer.add_child(sprite)
#	render_target_update_mode = Viewport.UPDATE_ONCE
	yield(get_tree(), "idle_frame")
	# todo: this is apparently slow, find out if it is necessary
	return TextureUtils.viewport_to_image(get_texture())
