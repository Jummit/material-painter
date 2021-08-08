extends Reference

"""
A loaded asset

Each asset loads a file. There are different asset types that can load
different files, for example textures, brushes and materials.
"""

var name : String
var path : String
var data

func _init(_path : String) -> void:
	path = _path
	name = path.get_file().get_basename()
	var dir := Directory.new()
	if dir.file_exists(path):
		_load_data()


func _load_data() -> void:
	data = load(path)


static func get_type() -> String:
	return ""
