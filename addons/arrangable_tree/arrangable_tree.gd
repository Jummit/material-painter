extends Tree

var items := []

# overide this to customize how items are set up
func setup_item(tree_item : TreeItem, item) -> void:
	pass


func update_tree() -> void:
	clear()
	var root := create_item()
	for item in items:
		var tree_item := create_item(root)
		tree_item.set_metadata(0, item)
		setup_item(tree_item, item)


func get_drag_data(position : Vector2):
	var preview := Label.new()
	preview.text = get_selected().get_text(0)
	set_drag_preview(preview)
	return get_item_at_position(position)


func can_drop_data(_position : Vector2, data) -> bool:
	drop_mode_flags = DROP_MODE_INBETWEEN
	return data is TreeItem


func drop_data(position : Vector2, data) -> void:
	# TODO: fix moving items
	pass
