extends ItemList

func _ready():
	load_textures("res://textures/")


func load_textures(path : String) -> void:
	var dir := Directory.new()
	dir.open(path)
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		file_name = dir.get_next()
		var file := path.plus_file(file_name)
		if ResourceLoader.exists(file, "Texture"):
			add_item(file_name.get_basename(), load(file))
			set_item_metadata(get_item_count() - 1, file)


func get_drag_data(position : Vector2):
	var item := get_item_at_position(position, true)
	if item != -1:
		var icon := get_item_icon(get_item_at_position(position))
		var preview := TextureRect.new()
		preview.rect_size = Vector2(64, 64)
		preview.expand = true
		preview.texture = icon
		set_drag_preview(preview)
		return get_item_metadata(item)
