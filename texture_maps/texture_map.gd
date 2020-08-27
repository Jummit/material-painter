extends Resource

enum BlendingMode {
	NORMAL,
	ADD,
	SUBTRACT,
	MULTIPLY,
}

export var name := ""
export(BlendingMode) var blending_mode := BlendingMode.NORMAL
