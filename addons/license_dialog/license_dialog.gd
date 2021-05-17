extends AcceptDialog

"""
A dialog inspired by the Godot Engine `About` popup

Shows the components used in the software and their licenses.
Some licenses are added by default.
"""

onready var tab_container : TabContainer = $TabContainer
onready var license_text : RichTextLabel = $TabContainer/ProgramLicense/LicenseText
onready var info_text_label : RichTextLabel = $TabContainer/ThirdPartyLicenses/HBoxContainer/InfoTextLabel
onready var component_tree : Tree = $TabContainer/ThirdPartyLicenses/HBoxContainer/ComponentTree


# The name of the program that uses the components.
export var program_name : String
# The license of the main program.
export(String, MULTILINE) var program_license : String

# A map of component names to their license texts.
var components : Dictionary setget set_components
# A map of license names to their complete texts.
var licenses : Dictionary setget set_licenses

var all_components := ""
var all_licenses := ""

func _ready() -> void:
	tab_container.set_tab_title(0, program_name + " License")
	tab_container.set_tab_title(1, "Third-Party Licenses")
	license_text.text = program_license


func set_components(to : Dictionary) -> void:
	components = to
	_update_tree()


func set_licenses(to : Dictionary) -> void:
	licenses = to
	_update_tree()


func _update_tree() -> void:
	component_tree.clear()
	var root := component_tree.create_item()
	
	var components_item := component_tree.create_item(root)
	components_item.set_text(0, "Components")
	components_item.set_metadata(0, "components")
	for component in components:
		var component_item := component_tree.create_item(components_item)
		component_item.set_metadata(0, component)
		component_item.set_text(0, component)
	
	all_components = ""
	for component in components:
		all_components += "%s\n%s\n\n" % [component, indent(
				components[component])]
	
	var licenses_item := component_tree.create_item(root)
	licenses_item.set_text(0, "Licenses")
	licenses_item.set_metadata(0, "licenses")
	for license in licenses:
		var license_item := component_tree.create_item(licenses_item)
		license_item.set_metadata(0, license)
		license_item.set_text(0, license)
	
	all_licenses = ""
	for license in licenses:
		all_licenses += "%s\n%s\n\n" % [license, indent(licenses[license])]


func _on_ComponentTree_item_selected() -> void:
	var metadata : String = component_tree.get_selected().get_metadata(0)
	var text : String
	match metadata:
		"components":
			text = all_components
		"licenses":
			text = all_licenses
		var item:
			if item in components:
				text = components[item]
			else:
				text = licenses[item]
	info_text_label.text = text


static func indent(string : String) -> String:
	return "	" + string.replace("\n", "\n	")
