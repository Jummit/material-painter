extends Panel

onready var properties_container : VBoxContainer = $Properties

signal values_changed

class Property:
	var name : String
	var value
	var changed_signal : String
	
	func _init(_changed_signal : String):
		changed_signal = _changed_signal
	
	func get_control() -> Control:
		return Control.new()
	
	func get_value_from_control(control : Control):
		pass

class EnumProperty extends Property:
	var choices : PoolStringArray
	
	func _init(_name : String, _choices : PoolStringArray).("item_selected"):
		name = _name
		choices = _choices
	
	func get_control() -> Control:
		var option_button := OptionButton.new()
		for choice in choices:
			option_button.get_popup().add_item(choice)
		option_button.selected = 0
		return option_button
	
	func get_value_from_control(control : Control):
		control.selected

class StringProperty extends Property:
	func _init(_name : String).("text_changed"):
		name = _name
	
	func get_control() -> Control:
		return LineEdit.new()
	
	func get_value_from_control(control : Control):
		return control.text

class IntProperty extends Property:
	func _init(_name : String).("changed"):
		name = _name
	
	func get_control() -> Control:
		return HSlider.new()
	
	func get_value_from_control(control : Control):
		return control.value

class FloatProperty extends Property:
	func _init(_name : String).("changed"):
		name = _name
	
	func get_control() -> Control:
		return HSlider.new()
	
	func get_value_from_control(control : Control):
		return control.value

class ColorProperty extends Property:
	func _init(_name : String).("color_changed"):
		name = _name
	
	func get_control() -> Control:
		return ColorPickerButton.new()
	
	func get_value_from_control(control : Control):
		return control.color

var properties := [] setget set_properties


func _ready():
	build()


func set_properties(to):
	properties = to
	build()


func build() -> void:
	for property_container in properties_container.get_children():
		property_container.queue_free()
	
	for property in properties:
		property = property as Property
		var property_container : HBoxContainer = load("res://property_panel/property_container.tscn").instance()
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


func _on_Property_changed():
	emit_signal("values_changed")
