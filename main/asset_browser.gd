extends TabContainer

"""
A list of assets that can be drag and dropped onto different UI elements

The tabs for each `AssetType` are generated procedurally.
Each `AssetType` defines how to load the asset file
and how to generate a thumbnail for it.
"""

signal asset_activated(asset)

var ASSET_TYPES := [
	TextureAssetType.new(),
	MaterialAssetType.new(),
	BrushAssetType.new(),
]

class AssetType:
	var name : String
	var directory : String
	
	func _init(_name : String, _directory : String) -> void:
		name = _name
		directory = _directory
	
	func _generate_preview(_asset : Resource) -> Texture:
		return null
	
	func _load(path : String):
		return load(path)

class TextureAssetType extends AssetType:
	func _init().("Textures", "user://textures") -> void:
		pass
	
	func _generate_preview(asset) -> Texture:
		var image := Image.new()
		image.load(asset)
		var image_texture := ImageTexture.new()
		image_texture.create_from_image(image)
		return image_texture
	
	func _load(path : String):
		return path

class MaterialAssetType extends AssetType:
	const MaterialLayer = preload("res://layers/material_layer.gd")
	const LayerTexture = preload("res://layers/layer_texture.gd")
	const LayerMaterial = preload("res://layers/layer_material.gd")
	
	func _init().("Materials", "user://materials") -> void:
		pass
	
	func _generate_preview(asset : Resource) -> Texture:
		var material_to_render := LayerMaterial.new()
		material_to_render.layers.append(asset)
		return yield(PreviewRenderer.get_preview_for_material(material_to_render, Vector2(128, 128)), "completed")

class BrushAssetType extends AssetType:
	func _init().("Brushes", "user://brushes") -> void:
		pass

func _ready():
	if ProjectSettings.get_setting("application/config/load_assets"):
		for asset_type in ASSET_TYPES:
			load_assets(asset_type)


func load_assets(asset_type : AssetType) -> void:
	var item_list := ItemList.new()
	item_list.name = asset_type.name
	item_list.icon_mode = ItemList.ICON_MODE_TOP
	item_list.same_column_width = true
	item_list.max_columns = 100
	item_list.fixed_icon_size = Vector2(128, 128)
	item_list.set_drag_forwarding(self)
	item_list.connect("item_activated", self, "_on_AssetList_item_activated", [item_list])
	add_child(item_list)
	
	var dir := Directory.new()
	dir.make_dir_recursive(asset_type.directory)
	dir.open(asset_type.directory)
	dir.list_dir_begin(true)
	var file_name := dir.get_next()
	while file_name != "":
		var file := asset_type.directory.plus_file(file_name)
		var asset = asset_type._load(file)
		var id := item_list.get_item_count()
		var preview = asset_type._generate_preview(asset)
		if preview is GDScriptFunctionState:
			preview = yield(preview, "completed")
		item_list.add_item(file.get_file().get_basename(), preview)
		item_list.set_item_metadata(id, {type = asset_type.name, asset = asset})
		file_name = dir.get_next()
		yield(get_tree(), "idle_frame")


func get_drag_data_fw(position : Vector2, _from : Control):
	var item_list : ItemList = get_child(current_tab)
	var item := item_list.get_item_at_position(position, true)
	if item != -1:
		var preview := TextureRect.new()
		preview.rect_size = Vector2(64, 64)
		preview.expand = true
		preview.texture = item_list.get_item_icon(item)
		set_drag_preview(preview)
		return item_list.get_item_metadata(item)


func _on_AssetList_item_activated(index : int, item_list : ItemList) -> void:
	emit_signal("asset_activated", item_list.get_item_metadata(index))
