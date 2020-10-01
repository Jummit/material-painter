extends Viewport

const TextureUtils = preload("res://utils/texture_utils.gd")
const LayerMaterial = preload("res://layers/layer_material.gd")
const Brush = preload("res://addons/painter/brush.gd")

onready var model : MeshInstance = $Model
onready var painter : Node = $Painter
onready var paint_viewport : Viewport = $PaintViewport
onready var mesh_instance : MeshInstance = $PaintViewport/MeshInstance
onready var paint_line : Line2D = $PaintLine

func get_preview_for_material(material : LayerMaterial, result_size : Vector2) -> ImageTexture:
	yield(material.update_all_layer_textures(result_size), "completed")
	yield(material.update_results(result_size), "completed")
	size = result_size
	model.load_layer_material_maps(material)
	render_target_update_mode = Viewport.UPDATE_ONCE
	yield(VisualServer, "frame_post_draw")
	return TextureUtils.viewport_to_image(get_texture())


func get_preview_for_brush(brush : Brush, result_size : Vector2) -> ImageTexture:
	if paint_viewport.size != result_size:
		paint_viewport.size = result_size
		yield(painter.set_mesh_instance(mesh_instance), "completed")
		yield(painter.update_view(paint_viewport), "completed")
		
	paint_viewport.size = result_size
	painter.brush = brush
	yield(painter.clear(), "completed")
	var last_point := paint_line.points[0]
	for point_num in range(1, paint_line.points.size()):
		var point = paint_line.points[point_num]
		yield(painter.paint(last_point, point), "completed")
		last_point = point
	return TextureUtils.viewport_to_image(painter.result)
