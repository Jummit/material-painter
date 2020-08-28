extends Viewport

func blend(texture_layers : Array) -> Texture:
	for back_buffer in get_children():
		back_buffer.free()
	
	for texture_layer in texture_layers:
		var back_buffer := BackBufferCopy.new()
		back_buffer.copy_mode = BackBufferCopy.COPY_MODE_VIEWPORT
		back_buffer.name = texture_layer.name
		add_child(back_buffer)
		
		var sprite := Sprite.new()
		sprite.texture = texture_layer.texture
		sprite.centered = false
		sprite.material = ShaderMaterial.new()
		sprite.material.shader = load("res://addons/blending/blend_shaders/%s.shader" % texture_layer.properties.blend_mode)
		sprite.material.set_shader_param("value", texture_layer.properties.opacity)
		back_buffer.add_child(sprite)
#	render_target_update_mode = Viewport.UPDATE_ONCE
	yield(get_tree(), "idle_frame")
	return get_texture()
