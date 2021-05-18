extends Reference

var name : String
# warning-ignore:unused_class_variable
var type : int
var path : String
var type_name : String
var data

func _init(_type_name : String, _path : String) -> void:
	type_name = _type_name
	path = _path
	name = path.get_file().get_basename()
	var dir := Directory.new()
	if dir.file_exists(path):
		_load_data()


func _load_data() -> void:
	data = load(path)
