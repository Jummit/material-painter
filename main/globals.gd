extends Node

"""
Global constants and application state
"""

# warning-ignore-all:unused_class_variable
var mesh : Mesh setget set_mesh
var selected_tool : int = Tools.PAINT
var current_file : SaveFile setget set_current_file
var editing_layer_material : LayerMaterial setget set_editing_layer_material
var result_size := Vector2(2048, 2048)
var undo_redo := UndoRedo.new()

signal mesh_changed(mesh)
signal current_file_changed
signal editing_layer_material_changed

enum Tools {
	TRIANGLE,
	QUADS,
	MESH_ISLANDS,
	UV_ISLANDS,
	FLAT_SURFACE,
	PAINT,
}

const SaveFile = preload("res://resources/save_file.gd")
const LayerMaterial = preload("res://resources/material/layer_material.gd")

const TEXTURE_MAP_TYPES := ["albedo", "emission", "height",
		"ao", "metallic", "roughness"]
const BLEND_MODES := ["normal", "add", "subtract", "multiply",
		"overlay", "screen", "darken", "lighten", "soft-light",
		"color-burn", "color-dodge"]

func set_mesh(to) -> void:
	mesh = to
	current_file.model_path = to.resource_path
	current_file.layer_materials.resize(mesh.get_surface_count())
	for surface in mesh.get_surface_count():
		if not current_file.layer_materials[surface]:
			current_file.layer_materials[surface] = LayerMaterial.new()
	current_file.layer_materials.front().update(true)
	set_editing_layer_material(current_file.layer_materials.front())
	emit_signal("mesh_changed", mesh)


func set_current_file(save_file : SaveFile, announce := true) -> void:
	current_file = save_file
	for layer_material in current_file.layer_materials:
		var result = layer_material.update(true)
		if result is GDScriptFunctionState:
			yield(result, "completed")
	if announce:
		emit_signal("current_file_changed")


func set_editing_layer_material(to) -> void:
	editing_layer_material = to
	emit_signal("editing_layer_material_changed")


func get_global_asset_path(path : String) -> String:
	var local_path := current_file.resource_path.get_base_dir() +\
			path.substr("local".length())
	return local_path if path.begins_with("local") else path
