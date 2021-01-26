"""
Utility to save and load layouts as json files
"""

static func save_layout(root : Container, layout_file : String) -> void:
	var layout := {
		windows = _store_layout(root),
		popped_out = []
	}
	
	for window in root.get_tree().get_nodes_in_group("Windows"):
		var parent : Control = window.get_parent()
		if parent is WindowDialog:
			var data := {
				x = parent.rect_position.x,
				y = parent.rect_position.y,
				width = parent.rect_size.x,
				height = parent.rect_size.y,
				name = window.name,
			}
			if window.has_meta("layout"):
				data.metadata = window.get_meta("layout")
			layout.popped_out.append(data)
	
	var file := File.new()
	file.open(layout_file, File.WRITE)
	file.store_string(to_json(layout))
	file.close()


static func load_layout(root : Node, layout_file : String) -> void:
	var file := File.new()
	file.open(layout_file, File.READ)
	var layout : Dictionary = parse_json(file.get_as_text())
	file.close()
	
	var windows := {}
	for window in root.get_tree().get_nodes_in_group("Windows"):
		if window.get_parent() is WindowDialog:
			window.get_parent().queue_free()
		window.get_parent().remove_child(window)
		windows[window.name] = window
	
	for popped_out in layout.popped_out:
		var panel : Panel = windows[popped_out.name]
		var window_dialog : WindowDialog = panel.put_in_window()
		window_dialog.rect_position = Vector2(popped_out.x, popped_out.y)
		window_dialog.rect_size = Vector2(popped_out.width, popped_out.height)
		if "metadata" in popped_out:
			panel.set_meta("layout", popped_out.metadata)
	
	_remove_containers(root)
	_load_individual_layout(root, layout.windows, windows)


static func _store_layout(root : Container) -> Dictionary:
	var layout := {
		type = root.get_class(),
		children = []
	}
	if root is SplitContainer and root.split_offset:
		layout.split = root.split_offset
	
	for node in root.get_children():
		if node is Panel:
			var data := {
				name = node.name,
			}
			if not node.visible:
				data.visible = false
			if node.has_meta("layout"):
				data.metadata = node.get_meta("layout")
			layout.children.append(data)
		else:
			layout.children.append(_store_layout(node))
	
	return layout


static func _remove_containers(root : Node) -> void:
	for child in root.get_children():
		if child is Container:
			root.remove_child(child)
			_remove_containers(child)


static func _load_individual_layout(root : Node, layout : Dictionary,
		windows : Dictionary) -> void:
	var container : Container = ClassDB.instance(layout.type)
	container.anchor_right = 1
	container.anchor_bottom = 1
	for window in layout.children:
		if "name" in window:
			var panel : Panel = windows[window.name]
			container.add_child(panel)
			panel.visible = true if not "visible" in window else window.visible
			if "metadata" in window:
				panel.set_meta("layout", window.metadata)
			panel.emit_signal("layout_changed")
		else:
			_load_individual_layout(container, window, windows)
	root.add_child(container)
	if container is SplitContainer and "split" in layout:
		container.split_offset = layout.split
	if container is TabContainer:
		container.drag_to_rearrange_enabled = true
