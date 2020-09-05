extends TabContainer

"""
A list of texture that can be drag and droped onto different UI elements
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

class TextureAssetType extends AssetType:
	func _init().("Textures", "textures") -> void:
		pass
	
	func _generate_preview(asset : Resource) -> Texture:
		return asset as Texture

class MaterialAssetType extends AssetType:
	func _init().("Materials", "materials") -> void:
		pass
	
	func _generate_preview(_asset : Resource) -> Texture:
		return null

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
	add_child(item_list)
	
	var folder := "res://assets/".plus_file(asset_type.directory)
	var dir := Directory.new()
	dir.open(folder)
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		file_name = dir.get_next()
		var file := folder.plus_file(file_name)
		if ResourceLoader.exists(file):
			var asset := load(file)
			var id := item_list.get_item_count() - 1
			item_list.add_item(file.get_file().get_basename(), asset_type._generate_preview(asset))
			item_list.set_item_metadata(id, asset)


func get_drag_data(position : Vector2):
	var item_list : ItemList = get_child(current_tab)
	var item := item_list.get_item_at_position(position, true)
	if item != -1:
		var preview := TextureRect.new()
		preview.rect_size = Vector2(64, 64)
		preview.expand = true
		preview.texture = item_list.get_item_icon(item)
		set_drag_preview(preview)
		return {type = "asset", asset = item_list.get_item_metadata(item)}
