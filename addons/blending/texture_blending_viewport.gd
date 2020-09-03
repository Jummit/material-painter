extends Viewport

const TextureUtils = preload("res://utils/texture_utils.gd")

func blend(layers : Array, options : Array) -> ImageTexture:
	for layer in layers.size():
		var layer_texture : Texture = layers[layer]
		
		if size < layer_texture.get_size():
			size = layer_texture.get_size()
		
		var back_buffer := BackBufferCopy.new()
		back_buffer.copy_mode = BackBufferCopy.COPY_MODE_VIEWPORT
		add_child(back_buffer)
		
		var sprite := Sprite.new()
		sprite.texture = layer_texture
		sprite.centered = false
		setup_sprite(sprite, options[layer])
		back_buffer.add_child(sprite)
	render_target_update_mode = Viewport.UPDATE_ONCE
	yield(get_tree(), "idle_frame")
	yield(get_tree(), "idle_frame")
	# todo: this is apparently slow, find out if it is necessary
	
	var texture := TextureUtils.viewport_to_image(get_texture())
	for back_buffer in get_children():
		back_buffer.free()
	
	size = Vector2.ZERO
	
	return texture


func setup_sprite(sprite : Sprite, options : Dictionary) -> void:
	sprite.material = ShaderMaterial.new()
	sprite.material.shader = load("res://addons/blending/blend_shaders/%s.shader" % options.blend_mode)
	sprite.material.set_shader_param("value", options.opacity)
