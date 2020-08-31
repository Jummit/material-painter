extends Viewport

const TextureUtils = preload("res://utils/texture_utils.gd")

# todo: use multiple blending viewports to avoid conflicts?

func blend(textures : Array, options : Array) -> ImageTexture:
	for back_buffer in get_children():
		back_buffer.free()
	
	if not textures.empty():
		size = (textures[0] as Texture).get_size()
	
	for layer in textures.size():
		var texture : Texture = textures[layer]
		
		var back_buffer := BackBufferCopy.new()
		back_buffer.copy_mode = BackBufferCopy.COPY_MODE_VIEWPORT
		add_child(back_buffer)
		
		var sprite := Sprite.new()
		sprite.texture = texture
		sprite.centered = false
		setup_sprite(sprite, options[layer])
		back_buffer.add_child(sprite)
	render_target_update_mode = Viewport.UPDATE_ONCE
	yield(get_tree(), "idle_frame")
	yield(get_tree(), "idle_frame")
	# todo: this is apparently slow, find out if it is necessary
	var texture := TextureUtils.viewport_to_image(get_texture())
	return texture


func setup_sprite(sprite : Sprite, options : Dictionary) -> void:
	sprite.material = ShaderMaterial.new()
	sprite.material.shader = load("res://addons/blending/blend_shaders/%s.shader" % options.blend_mode)
	sprite.material.set_shader_param("value", options.opacity)
