extends Viewport

const TextureUtils = preload("res://utils/texture_utils.gd")
const LayerMaterial = preload("res://layers/layer_material.gd")

onready var model : MeshInstance = $Model

func get_preview_for_material(material : LayerMaterial, result_size : Vector2) -> ImageTexture:
	yield(material.update_all_layer_textures(result_size), "completed")
	yield(material.update_results(result_size), "completed")
	size = result_size
	model.load_layer_material_maps(material)
	render_target_update_mode = Viewport.UPDATE_ONCE
	yield(VisualServer, "frame_post_draw")
	return TextureUtils.viewport_to_image(get_texture())
