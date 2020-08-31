extends Panel

onready var properties_container : VBoxContainer = $Properties

const Property = preload("res://addons/property_panel/properties.gd").Property

signal values_changed

var properties := [] setget set_properties

func _ready():
	build()


func set_properties(to):
	properties = to
	build()


func build() -> void:
	for property_container in properties_container.get_children():
		# use ´free´ instead of ´queue_free´ to immediatly remove nodes
		# because otherwise duplicate properties get automatically renamed
		property_container.free()
	
	for property in properties:
		property = property as Property
		var property_container : HBoxContainer = load("res://addons/property_panel/property_container/property_container.tscn").instance()
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


func load_values(values) -> void:
#func load_values(values : Dictionary) -> void:
	for value in values.keys():
		properties_container.get_node(value).set_value(values[value])


func _on_Property_changed():
	emit_signal("values_changed")
