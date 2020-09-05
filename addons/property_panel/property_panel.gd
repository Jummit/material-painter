extends Panel

"""
A inspector-like panel that builds a list of `PropertyContainers`s from its `properties`

The resulting values can be retrieved using `get_property_value` and `get_property_values`.
`get_property_values` returns a `Dictionary` with the property names as keys and the values as values.
A `Dictionary` similar to the result of `get_property_values` can be fed to `load_values` to update the values of the `PropertyContainers`s.
"""

signal values_changed

var properties := [] setget set_properties

onready var properties_container : VBoxContainer = $Properties

func _ready():
	setup_property_containers()


func set_properties(to):
	properties = to
	setup_property_containers()


func setup_property_containers() -> void:
	for property_container in properties_container.get_children():
		# use ´free´ instead of ´queue_free´ to immediatly remove nodes
		# because otherwise duplicate properties get automatically renamed
		property_container.free()
	
	for property in properties:
		property = property
		var property_container = load("res://addons/property_panel/property_container/property_container.tscn").instance()
		property_container.name = property.name
		property_container.connect("property_changed", self, "_on_Property_changed")
		properties_container.add_child(property_container)
		property_container.setup(property)


func get_property_value(property_name : String):
	return properties_container.get_node(property_name).get_value()


func get_property_values() -> Dictionary:
	var values := {}
	for property_container in properties_container.get_children():
		values[property_container.name] = get_property_value(property_container.name)
	return values


func load_values(values : Dictionary) -> void:
	set_block_signals(true)
	for value in values.keys():
		properties_container.get_node(value).set_value(values[value])
	set_block_signals(false)


func _on_Property_changed():
	emit_signal("values_changed")
