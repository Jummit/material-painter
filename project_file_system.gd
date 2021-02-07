extends Reference

var _project_file : String
var _project_dir : String

func _init(project_file := "") -> void:
	_project_file = project_file
	_project_dir = _project_file.get_base_dir()


func get_global_path(path : String) -> String:
	if path.begins_with("local"):
		return _project_dir.plus_file(path.trim_prefix("local"))
	else:
		return path


func get_global_asset_dir() -> String:
	return "user://assets"


func get_local_asset_dir() -> String:
	return _project_dir.plus_file("assets")
