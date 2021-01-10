extends Node

"""
Utility for rendering previews of `Asset`s used in the `AssetBrowser`

Renders previews of `MaterialAssetTypes`s, `BrushAssetTypes`s and `HDRAssetTypes`.

Replaces all local textures of the material with res://preview_renderer to make
mesh maps used in the material work.
"""

const TextureUtils = preload("res://utils/texture_utils.gd")
const Brush = preload("res://addons/painter/brush.gd")
const FileTextureLayer = preload("res://resources/texture/layers/file_texture_layer.gd")

onready var material_viewport : Viewport = $MaterialViewport
onready var model : MeshInstance = $MaterialViewport/Model

onready var brush_viewport : Viewport = $BrushViewport
onready var paint_line : Line2D = $BrushViewport/PaintLine
onready var painter : Node = $BrushViewport/Painter
onready var mesh_instance : MeshInstance = $BrushViewport/MeshInstance

onready var hdr_viewport : Viewport = $HDRViewport
onready var sky_dome : MeshInstance = $HDRViewport/SkyDome

func get_preview_for_material(material : Resource,
		result_size : Vector2) -> ImageTexture:
	material = material.duplicate(true)
	for material_layer in material.get_flat_layers():
		for layer_texture in material_layer.get_layer_textures():
			for texture_layer in layer_texture.get_flat_layers():
				if texture_layer is FileTextureLayer:
					texture_layer.cached_path = ""
					if texture_layer.path.begins_with("local"):
						texture_layer.path = "res://preview_renderer" +\
							texture_layer.path.trim_prefix("local")
	var result = material.update(true)
	if result is GDScriptFunctionState:
		yield(result, "completed")
	model.material_override = material.get_material()
	material_viewport.size = result_size
	material_viewport.render_target_update_mode = Viewport.UPDATE_ONCE
	yield(VisualServer, "frame_post_draw")
	var texture := TextureUtils.viewport_to_image(material_viewport.get_texture())
	return texture


func get_preview_for_brush(brush : Brush, result_size : Vector2) -> ImageTexture:
	if brush_viewport.size != result_size:
		brush_viewport.size = result_size
		yield(painter.set_mesh_instance(mesh_instance), "completed")
		yield(painter.update_view(brush_viewport), "completed")
	
	painter.brush = brush
	yield(painter.clear(), "completed")
	var last_point := paint_line.points[0]
	for point_num in range(1, paint_line.points.size()):
		var point = paint_line.points[point_num]
		yield(painter.paint(last_point, point), "completed")
		last_point = point
	return TextureUtils.viewport_to_image(painter.result)


func get_preview_for_hdr(hdr : Image, result_size : Vector2) -> Texture:
	var albedo_texture := ImageTexture.new()
	albedo_texture.create_from_image(hdr)
	sky_dome.material_override.albedo_texture = albedo_texture
	hdr_viewport.size = result_size
	hdr_viewport.render_target_update_mode = Viewport.UPDATE_ONCE
	yield(VisualServer, "frame_post_draw")
	return TextureUtils.viewport_to_image(hdr_viewport.get_texture())
