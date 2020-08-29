extends Viewport

var n := 1
var u := 1
const TextureUtils = preload("res://utils/texture_utils.gd")

# todo: use multiple blending viewports to avoid conflicts?

func blend(textures : Array, blend_modes : PoolStringArray = [], opacity_values : PoolRealArray = [], default_blend_mode := "normal", default_opacity := 1.0) -> ImageTexture:
	print("blending %s textures : %s" % [textures.size(), textures])
	for back_buffer in get_children():
		back_buffer.free()
	
	for layer in textures.size():
		var texture : Texture = textures[layer]
		var blend_mode : String = default_blend_mode if blend_modes.size() <= layer else blend_modes[layer]
		var opacity : float = default_opacity if opacity_values.size() <= layer else opacity_values[layer]
		
		var back_buffer := BackBufferCopy.new()
		back_buffer.copy_mode = BackBufferCopy.COPY_MODE_VIEWPORT
		add_child(back_buffer)
		
		print("Blending %s with opacity %s and blend mode %s" % [texture, opacity, blend_mode])
#		var data = texture.get_data()
#		if data:
#			data.save_png("res://using/%s.png" % u)
#			u += 1
		var sprite := Sprite.new()
		sprite.texture = texture
		sprite.centered = false
		sprite.material = ShaderMaterial.new()
		sprite.material.shader = load("res://addons/blending/blend_shaders/%s.shader" % blend_mode)
		sprite.material.set_shader_param("value", opacity)
		back_buffer.add_child(sprite)
	render_target_update_mode = Viewport.UPDATE_ONCE
	yield(get_tree(), "idle_frame")
	yield(get_tree(), "idle_frame")
	# todo: this is apparently slow, find out if it is necessary
	var texture := TextureUtils.viewport_to_image(get_texture())
#	texture.get_data().save_png("res://results/%s.png" % n)
#	n += 1
	return texture
