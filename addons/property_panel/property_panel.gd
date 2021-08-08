extends Panel

"""
An inspector-like panel that builds a list of `PropertyContainer`s

When the `properties` are set, a `PropertyContainer` is generated for each
property.

The resulting values can be retrieved using `get_property_value` and
`get_property_values`.

A `Dictionary` similar to the result of `get_property_values` can be given to
`load_values` to update the values of the `PropertyContainers`s.
"""

enum Orientation {
	VERTICAL,
	HORIZONTAL,
}

signal property_changed(property, value)

# If the properties should be alligned from left to right or from top to bottom.
export(Orientation) var orientation := Orientation.VERTICAL

var properties := [] setget set_properties

var _property_container_scene : PackedScene = load("res://addons/property_panel/property_container/property_container.tscn")

const PropertyContainer = preload("res://addons/property_panel/property_container/property_container.gd")

onready var properties_container : Container
onready var scroll_container : ScrollContainer = $ScrollContainer

func _ready():
# warning-ignore:incompatible_ternary
	properties_container = HBoxContainer.new() if\
			orientation == Orientation.HORIZONTAL else VBoxContainer.new()
	properties_container.size_flags_horizontal = SIZE_EXPAND_FILL
	properties_container.size_flags_vertical = SIZE_EXPAND_FILL
	scroll_container.add_child(properties_container)
	_setup_property_containers()


func get_property_value(property_name : String):
	return (properties_container.get_node(property_name) as PropertyContainer)\
			.get_value()


func set_property_value(property_name : String, value):
	return (properties_container.get_node(property_name) as PropertyContainer)\
			.set_value(value)


# Returns true if the property is exposed.
func has_property(property_name : String) -> bool:
	return properties_container.has_node(property_name)


# Returns a `Dictionary` with the property names as keys and the values as
# values.
func get_property_values() -> Dictionary:
	var values := {}
	for property_container in properties_container.get_children():
		if not property_container is Label:
			values[property_container.name] = get_property_value(
					property_container.name)
	return values


# Store the values in an instance.
func store_values(instance) -> void:
	var property_values := get_property_values()
	for value in property_values:
		instance.set(value, property_values[value])


# Load the property values from any instance.
func load_values(instance) -> void:
	set_block_signals(true)
	for property_container in properties_container.get_children():
		if not property_container is Label:
			var value = instance.get(property_container.property.name)
			if value:
				property_container.set_value(value)
	set_block_signals(false)


# Clear the panel, removing every property.
func clear() -> void:
	set_properties([])


func set_properties(to : Array) -> void:
	properties = to
	_setup_property_containers()


func _setup_property_containers() -> void:
	for property_container in properties_container.get_children():
		# use ´free´ instead of ´queue_free´ to immediatly remove nodes
		# because otherwise duplicate properties get automatically renamed
		property_container.free()
		
	for property in properties:
		if property is String:
			var label := Label.new()
			label.align = Label.ALIGN_CENTER
			label.text = property
			properties_container.add_child(label)
		else:
			var property_container = _property_container_scene.instance()
			property_container.name = property.name
			property_container.connect("property_changed", self,
					"_on_Property_changed", [property_container])
			
			properties_container.add_child(property_container)
			property_container.setup(property)


func _on_Property_changed(value, property_container : PropertyContainer):
	emit_signal("property_changed", property_container.property.name, value)
