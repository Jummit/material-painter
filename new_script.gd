tool
extends EditorScript

var tests := {
	normal = ["normal"],
	Normal = ["normal"],
	NormalTest = ["normal", "test"],
	normal_test = ["normal", "test"],
	Normal_test = ["normal", "test"],
	NormalTest_foo = ["normal", "test", "foo"],
	NormalTest_foo51 = ["normal", "test", "foo"],
}

func _run() -> void:
	for test in tests:
		if not get_tags(test) == PoolStringArray(tests[test]):
			print("%s should be %s" % [get_tags(test), tests[test]])
"""
normal -> Normal
Normal -> Normal
NormalTest -> Normal, Test
normal_test -> Normal, Test
Normal_test -> Normal, Test
NormalTest_foo -> Normal, Test, Foo
"""
	

func get_tags(name : String) -> PoolStringArray:
	for letter in name:
		if int(letter):
			name = name.replace(letter, "")
		if letter.to_upper() == letter:
			name = name.replace(letter, "_" + letter)
	return name.to_lower().split("_", false)
