extends Viewport

const TextureUtils = preload("res://utils/texture_utils.gd")
const Brush = preload("res://addons/painter/brush.gd")
const FileTextureLayer = preload("res://resources/texture/layers/file_texture_layer.gd")

onready var model : MeshInstance = $Model
onready var painter : Node = $Painter
onready var paint_viewport : Viewport = $PaintViewport
onready var mesh_instance : MeshInstance = $PaintViewport/MeshInstance
onready var paint_line : Line2D = $PaintLine

func get_preview_for_material(material : Resource, result_size : Vector2) -> ImageTexture:
	material = material.duplicate(true)
	for material_layer in material.get_flat_layers():
		for layer_texture in material_layer.get_layer_textures():
			for texture_layer in layer_texture.get_flat_layers():
				if texture_layer is FileTextureLayer:
					texture_layer.cached_path = ""
					if texture_layer.path.begins_with("local"):
						texture_layer.path = "res://preview_renderer/" +\
								texture_layer.path.substr("local".length())
	var result = material.update(true)
	if result is GDScriptFunctionState:
		yield(result, "completed")
	size = result_size
	model.material_override = material.get_material()
	render_target_update_mode = Viewport.UPDATE_ONCE
	yield(VisualServer, "frame_post_draw")
	return TextureUtils.viewport_to_image(get_texture())


func get_preview_for_brush(brush : Brush, result_size : Vector2) -> ImageTexture:
	if paint_viewport.size != result_size:
		paint_viewport.size = result_size
		yield(painter.set_mesh_instance(mesh_instance), "completed")
		yield(painter.update_view(paint_viewport), "completed")
	
	painter.brush = brush
	yield(painter.clear(), "completed")
	var last_point := paint_line.points[0]
	for point_num in range(1, paint_line.points.size()):
		var point = paint_line.points[point_num]
		yield(painter.paint(last_point, point), "completed")
		last_point = point
	return TextureUtils.viewport_to_image(painter.result)
