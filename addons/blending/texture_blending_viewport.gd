extends Viewport

"""
A `Viewport` for blending layer-based texture lists using shaders

Creates a list of `TextureRect`s as children of `BackBufferCopy`s to make the `TEXTURE` variable in shaders work.
"""

var busy := false

const TextureUtils = preload("res://utils/texture_utils.gd")

func blend(layers : Array, options : Array, result_size : Vector2) -> ImageTexture:
	size = result_size
	
	while busy:
		yield(VisualServer, "frame_post_draw")
	
	for layer in layers.size():
		var layer_texture : Texture = layers[layer]
		
		var back_buffer := BackBufferCopy.new()
		back_buffer.copy_mode = BackBufferCopy.COPY_MODE_VIEWPORT
		add_child(back_buffer)
		
		var texture_rect := TextureRect.new()
		texture_rect.expand = true
		texture_rect.rect_size = result_size
		texture_rect.texture = layer_texture
		_setup_texture(texture_rect, options[layer])
		back_buffer.add_child(texture_rect)
	
	render_target_update_mode = Viewport.UPDATE_ONCE
	# todo: wait for frame update instead of process tick
	busy = true
	yield(VisualServer, "frame_post_draw")
	busy = false
	
	# todo: this is apparently slow, find out if it is necessary
	var texture := TextureUtils.viewport_to_image(get_texture())
	
	for back_buffer in get_children():
		back_buffer.free()
	
	return texture


func _setup_texture(texture_rect : TextureRect, options : Dictionary) -> void:
	texture_rect.material = ShaderMaterial.new()
	# todo: cache shaders
	texture_rect.material.shader = load("res://addons/blending/blend_shaders/%s.shader" % options.blend_mode)
	texture_rect.material.set_shader_param("value", options.opacity)
