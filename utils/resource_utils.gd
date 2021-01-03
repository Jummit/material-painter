"""
Utilities for working with `Resource`s
"""

# workaround for https://github.com/godotengine/godot/issues/33079
static func deep_copy_of_resource(resource : Resource) -> Resource:
	ResourceSaver.save("user://.tmp_duplicate_resource.tres", resource)
	var dir := Directory.new()
	# don't use the cashed resource, as it will change on disk
	var copy := ResourceLoader.load("user://.tmp_duplicate_resource.tres", "", true)
	dir.remove("user://.tmp_duplicate_resource.tres")
	return copy
