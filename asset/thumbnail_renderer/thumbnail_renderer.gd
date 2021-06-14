extends Node

"""
Utility for rendering thumbnails of `Asset`s used in the `AssetBrowser`

Renders thumbnails of `MaterialAssetTypes`s, `BrushAssetTypes`s and `HDRAssetTypes`.

Replaces all local textures of the material with res://thumbnail_renderer to make
mesh maps used in the material work.
"""

var mesh : Mesh

const TextureUtils = preload("res://utils/texture_utils.gd")
const Brush = preload("res://main/brush.gd")
const MaterialLayerStack = preload("res://material/material_layer_stack.gd")
const MaterialGenerationContext = preload("res://material/material_generation_context.gd")
const Painter = preload("res://addons/painter/painter.gd")
const MaterialLayer = preload("res://material/material_layer.gd")
const LayerBlendViewportManager = preload("res://addons/layer_blending_viewport/layer_blend_viewport_manager.gd")
const TriplanarTextureGenerator = preload("res://addons/triplanar_texture_generator/triplanar_texture_generator.gd")
const NormalMapGenerationViewport = preload("res://addons/normal_map_generation_viewport/normal_map_generation_viewport.gd")

onready var material_viewport : Viewport = $MaterialViewport
onready var model : MeshInstance = $MaterialViewport/Model

onready var brush_viewport : Viewport = $BrushViewport
onready var paint_line : Line2D = $BrushViewport/PaintLine
onready var painter : Painter = $BrushViewport/Painter
onready var mesh_instance : MeshInstance = $BrushViewport/MeshInstance

onready var hdri_viewport : Viewport = $HDRIViewport
onready var sky_dome : MeshInstance = $HDRIViewport/SkyDome

onready var layer_blending_viewport : LayerBlendViewportManager = $LayerBlendingViewportManager
onready var normal_map_generation_viewport : NormalMapGenerationViewport = $NormalMapGenerationViewport
onready var triplanar_texture_generator : TriplanarTextureGenerator = $TriplanarTextureGenerator

func get_thumbnail_for_smart_material(material : MaterialLayer,
		result_size : Vector2) -> ImageTexture:
	var layer_mat := MaterialLayerStack.new()
	layer_mat.context = MaterialGenerationContext.new(layer_blending_viewport,
			normal_map_generation_viewport, triplanar_texture_generator)
	layer_mat.context.mesh = mesh
	layer_mat.add_layer(material, layer_mat, -1, false)
	var result = layer_mat.update()
	while result is GDScriptFunctionState:
		result = yield(result, "completed")
	model.material_override = layer_mat.get_material()
	material_viewport.size = result_size
	material_viewport.render_target_update_mode = Viewport.UPDATE_ONCE
	yield(VisualServer, "frame_post_draw")
	var texture := TextureUtils.viewport_to_image(material_viewport.get_texture())
	return texture


func get_thumbnail_for_brush(brush : Brush, result_size : Vector2) -> ImageTexture:
	if brush_viewport.size != result_size:
		brush_viewport.size = result_size
		yield(painter.set_mesh_instance(mesh_instance), "completed")
		yield(painter.update_view(brush_viewport), "completed")
	
	var brushes := []
	for map in Constants.TEXTURE_MAP_TYPES:
		brushes.append(brush.get_brush(map))
	painter.brushes = brushes
	yield(painter.clear(), "completed")
	var last_point := paint_line.points[0]
	for point_num in range(1, paint_line.points.size()):
		var point = paint_line.points[point_num]
		yield(painter.paint(last_point, point), "completed")
		last_point = point
	return TextureUtils.viewport_to_image(painter.get_result(0))


func get_thumbnail_for_hdri(hdri : Image, result_size : Vector2) -> Texture:
	var albedo_texture := ImageTexture.new()
	albedo_texture.create_from_image(hdri)
	(sky_dome.material_override as SpatialMaterial).albedo_texture = albedo_texture
	hdri_viewport.size = result_size
	hdri_viewport.render_target_update_mode = Viewport.UPDATE_ONCE
	yield(VisualServer, "frame_post_draw")
	return TextureUtils.viewport_to_image(hdri_viewport.get_texture())


func get_thumbnail_for_texture(texture : Image,
		result_size : Vector2) -> Texture:
	var smaller := ImageTexture.new()
	texture.resize(int(result_size.x), int(result_size.y),
			Image.INTERPOLATE_BILINEAR)
	smaller.create_from_image(texture)
	return smaller
