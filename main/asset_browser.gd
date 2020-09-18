extends TabContainer

"""
A list of assets that can be drag and dropped onto different UI elements
"""

var ASSET_TYPES := [
	TextureAssetType.new(),
	MaterialAssetType.new(),
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
	
	func _init().("Materials", "user://materials") -> void:
		pass
	
	func _generate_preview(asset : Resource):
		return ((asset as MaterialLayer).maps.values().front() as LayerTexture).generate_result(Vector2(128, 128), false)

func _ready():
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
	add_child(item_list)
	
	var dir := Directory.new()
	dir.open(asset_type.directory)
	dir.list_dir_begin(true)
	var file_name := dir.get_next()
	while file_name != "":
		var file := asset_type.directory.plus_file(file_name)
		var asset = asset_type._load(file)
		var id := item_list.get_item_count()
		item_list.add_item(file.get_file().get_basename(), asset_type._generate_preview(asset))
		item_list.set_item_metadata(id, {type = asset_type.name, asset = asset})
		file_name = dir.get_next()


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
