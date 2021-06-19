extends Tree

signal surface_selected(surface)

func _on_Main_mesh_changed(to : Mesh) -> void:
	clear()
	var root := create_item()
	for surface in to.get_surface_count():
		var item := create_item(root)
		item.set_metadata(0, surface)
		item.set_text(0, to.surface_get_material(surface).resource_name)


func _on_item_selected() -> void:
	emit_signal("surface_selected", get_selected().get_metadata(0))
