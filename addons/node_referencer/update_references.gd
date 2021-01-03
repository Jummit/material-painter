tool
extends EditorScript

var node_referencer = preload("res://addons/node_referencer/plugin.gd").new()

func _run():
	var updated := ""
	var root : Node = node_referencer.search_node_that_uses(
			get_editor_interface().get_edited_scene_root(),
			get_editor_interface().get_script_editor().get_current_script())
	for assign in OS.clipboard.split("\n"):
		var node_referenced = get_editor_interface().get_edited_scene_root().find_node(get_node_name(assign))
		updated += node_referencer.get_node_reference(
				node_referenced, root.get_path_to(node_referenced)) + "\n"
	OS.clipboard = updated


func get_node_name(string : String) -> String:
	if not "/" in string:
		return string.substr(string.find("$") + 1)
	return Array(string.replace('"', "").split("/")).back()
