tool
extends EditorScript

const TEMPLATE := """func _init({args}) -> void:
{assigns}"""

func _run() -> void:
	var args := ""
	var assigns := ""
	
	var declarations := OS.clipboard.replace("	", "").split("\n")
	for declaration in declarations:
		declaration = declaration as String
		var words : PoolStringArray = declaration.split(" ")
		args += "_" + declaration.trim_prefix("var ") + ", "
		assigns += "	%s = _%s\n" % [words[1], words[1]]
	
	var code := TEMPLATE.format({args = args.trim_suffix(", "), assigns = assigns})
	
	print("Constructor copied to clipboard")
	OS.clipboard = code
