extends Reference

"""
A class that can modify the vertex colors of the triangles of the same selection
island with the same color in `prepare_mesh`.
"""

# Returns a mesh where the vertex colors of selection islands have the same color.
static func prepare_mesh(mesh : Mesh, _surface : int) -> Mesh:
	return mesh


# Get a random color used to color a selectable island.
static func get_color() -> Color:
	return Color(randf(), randf(), randf())
