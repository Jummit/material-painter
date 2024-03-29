extends Node

"""
Node that loads and organizes assets at runtime
"""

signal asset_loaded(asset)
signal asset_unloaded(asset)
signal dir_loaded
signal dir_unloaded

const TAG_PATH := "user://tags.json"

var thumbnails : Dictionary
var assets : Array
var assets_by_tags : Dictionary
var asset_tags : Dictionary
var asset_types := [
	load("res://asset/assets/brush_asset.gd"),
	load("res://asset/assets/hdri_asset.gd"),
	load("res://asset/assets/effect_asset.gd"),
	load("res://asset/assets/material_asset.gd"),
	load("res://asset/assets/smart_material_asset.gd"),
	load("res://asset/assets/texture_asset.gd"),
]

const Asset = preload("assets/asset.gd")

onready var thumbnail_renderer : Node = $ThumbnailRenderer

func _ready() -> void:
	load_asset_tags()
	var dir := Directory.new()
	dir.make_dir_recursive("user://assets")
	load_dir("user://assets")


# Asset loading / unloading

func load_dir(path : String) -> void:
	for asset in asset_types:
		var dir := Directory.new()
		var type_path := path.plus_file(asset.get_type())
		if dir.open(type_path) != OK:
			continue
		dir.list_dir_begin(true)
		var file_name := dir.get_next()
		while file_name:
			if not "thumbnail.png" in file_name:
				var result = load_asset(type_path.plus_file(file_name), asset)
				while result is GDScriptFunctionState:
					result = yield(result, "completed")
			file_name = dir.get_next()
		dir.list_dir_end()
	save_asset_tags()
	emit_signal("dir_loaded")


func unload_dir(path : String) -> void:
	for asset in assets:
		if asset.path.begins_with(path):
			unload_asset(asset)
	emit_signal("dir_unloaded")


func load_asset(path : String, type : GDScript) -> void:
	var asset : Asset = type.new(path)
	assets.append(asset)
	
	# Tag assignment.
	add_asset_tag(asset, asset.get_type())
	# Load stored tags.
	if path in asset_tags:
		for tag in asset_tags[path]:
			add_asset_tag(asset, tag)
	# Generate tags from name.
	var asset_name := asset.name
	for letter in asset_name:
		if int(letter):
			asset_name = asset_name.replace(letter, "")
		if letter.to_upper() == letter:
			asset_name = asset_name.replace(letter, "_" + letter)
	for tag in asset_name.to_lower().split("_", false):
		add_asset_tag(asset, tag)
	
	# Thumbnail generation.
	var dir := Directory.new()
	var thumbnail_path := get_thumbnail_path(asset)
	var thumbnail : Texture
	if dir.file_exists(thumbnail_path):
		var image := Image.new()
		image.load(thumbnail_path)
		thumbnail = ImageTexture.new()
		(thumbnail as ImageTexture).create_from_image(image)
	elif thumbnail_renderer.has_method("get_thumbnail_for_" + asset.get_type()):
		var result = thumbnail_renderer.call(
# warning-ignore:unsafe_property_access
# warning-ignore:unsafe_property_access
				"get_thumbnail_for_" + asset.get_type(), asset.data,
				Vector2(128, 128))
		while result is GDScriptFunctionState:
			result = yield(result, "completed")
		thumbnail = result
		thumbnail.get_data().save_png(thumbnail_path)
	thumbnails[path] = thumbnail
	
	emit_signal("asset_loaded", asset)


func unload_asset(asset : Asset) -> void:
	assets.erase(asset)
	for tag in asset_tags[asset]:
		assets_by_tags[tag].erase(asset)
	emit_signal("asset_unloaded", asset)


# Delete an asset file from disk.
func remove_asset(asset : Asset) -> void:
	# Delete asset files.
	var dir := Directory.new()
	dir.remove(asset.path)
	dir.remove(get_thumbnail_path(asset))
	
	# Remove asset from tag data.
	for tag in asset_tags[asset.path]:
		remove_asset_tag(asset, tag)
	asset_tags.erase(asset.path)
	save_asset_tags()


# Tags

func add_asset_tag(asset : Asset, tag : String) -> void:
	if not tag in assets_by_tags:
		assets_by_tags[tag] = [asset]
	elif not asset in assets_by_tags[tag]:
		assets_by_tags[tag].append(asset)
	if not asset.path in asset_tags:
		asset_tags[asset.path] = [tag]
	elif not tag in asset_tags[asset.path]:
		asset_tags[asset.path].append(tag)


func remove_asset_tag(asset : Asset, tag : String) -> void:
	if tag in assets_by_tags:
		assets_by_tags[tag].erase(asset)
	if asset.path in asset_tags:
		asset_tags[asset.path].erase(tag)


func save_asset_tags() -> void:
	var file := File.new()
	file.open(TAG_PATH, File.WRITE)
	file.store_string(to_json(asset_tags))
	file.close()


func load_asset_tags() -> void:
	var file := File.new()
	if file.open(TAG_PATH, File.READ) != OK:
		return
	asset_tags = parse_json(file.get_as_text())
	file.close()


# Misc

static func get_thumbnail_path(asset : Asset) -> String:
	return asset.path.get_base_dir().plus_file(asset.name + "_thumbnail.png")


func search(filter : String) -> Array:
	var search_terms := filter.to_lower().replace(",", " ").split(" ", false)
	if search_terms.empty():
		return assets
	var found := []
	for asset in assets:
		found.append(asset)
		for tag in search_terms:
			if not tag in PoolStringArray(asset_tags[asset.path]).join(" "):
				found.pop_back()
				break
	return found
