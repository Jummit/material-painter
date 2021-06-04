tool
extends Node

func generate(mesh : Mesh) -> ImageTexture:
	var b_mesh := MeshDataTool.new()
	if not mesh is ArrayMesh:
		b_mesh.create_from_surface(mesh.create_outline(0.0), 0)
	else:
		b_mesh.create_from_surface(mesh, 0)
	
	if not b_mesh.get_vertex_count() or not b_mesh.get_face_count():
		return ImageTexture.new()
	
	var triangles := []
	var vertices := []
	for i in b_mesh.get_vertex_count() :
		vertices.append(b_mesh.get_vertex(i))
	for i in b_mesh.get_face_count() :
		triangles.append({
			0 : b_mesh.get_face_vertex(i, 0 if mesh is ArrayMesh else 2),
			1 : b_mesh.get_face_vertex(i, 1),
			2 : b_mesh.get_face_vertex(i, 2 if mesh is ArrayMesh else 0),
			3 : i
		})
	
	var bvh := BVHNode.new()
	bvh.vertices = vertices
	bvh.triangles = triangles
	print("Generating BVH...")
	var time := OS.get_ticks_msec()
	var max_node_level := bvh.generate()
	print("BVH Generated!")
	print("Maximum Node Level : %d" % max_node_level)
	print("Time to generate BVH : %f" % ((OS.get_ticks_msec() - time) / 1000.0))
	
	var tex := ImageTexture.new()
	tex.create_from_image(bvh.image, 0)
	return tex


# The BVH (Bounding Volume Hierarchy) is used to making ray tracing on the GPU
# much more efficient.
class BVHNode:
	const MAX_TRIANGLES = 8
	const DATA_HEADER_SIZE = 1
	
	var aabb := AABB()
	var center : Vector3
	var level := 0
	
	var root := self
	var parent : BVHNode
	var left_node : BVHNode
	var right_node : BVHNode
	
	var triangles := []
	var vertices := []
	
	# The properties that follow are only made in the root node.
	var image : Image
	
	var _node_ids : Dictionary
	var _id_nodes : Dictionary
	var _node_data : Array
	var _data : Array
	
	# Gets all the nodes triangles, including its children.
	func get_triangles() -> Array:
		var tris := triangles.duplicate()
		if root == self:
			return tris
		
		if left_node:
			tris += left_node.get_triangles()
			tris += right_node.get_triangles()
		return tris
	
	# Takes the triangles and splits itself into smaller nodes until each node
	# has less than the maximum triangle count.
	# Returns the maximum level that the bvh generates down to.
	func generate() -> int:
		calculate_aabb()
		
		if root == self:
			_id_nodes = {}
			_node_ids = {}
			_node_ids[self] = 0
			_id_nodes[0] = self
			
			_data = [0, 0, 0, 0]
			_node_data = []
		else:
			var id := root._node_ids.size()
			root._node_ids[self] = id
			root._id_nodes[id] = self
		
		var data_offset := root._node_data.size()
		_append_4(root._data, int(data_offset / 4.0))
		_append_4(root._node_data, aabb.position.x, aabb.position.y, aabb.position.z, level)
		_append_4(root._node_data, aabb.end.x, aabb.end.y, aabb.end.z, 0)
		
		# Stop splitting if there's not enough triangle.
		if triangles.size() <= MAX_TRIANGLES:
			root._node_data[-1] = triangles.size()
			for tri in triangles :
				var vert_a : Vector3 = vertices[tri[0]]
				var vert_b : Vector3 = vertices[tri[1]]
				var vert_c : Vector3 = vertices[tri[2]]
				_append_4(root._node_data, vert_a.x, vert_a.y, vert_a.z)
				_append_4(root._node_data, vert_b.x, vert_b.y, vert_b.z)
				_append_4(root._node_data, vert_c.x, vert_c.y, vert_c.z)
			if root == self:
				_finalize_data()
			return level
		
		# Generate triangle centroids if there's non.
		if not triangles[0].has("centroid"):
			for i in triangles.size() :
				var tri : Dictionary = triangles[i]
				var tri_aabb := AABB()
				tri_aabb.position = vertices[tri[0]]
				tri_aabb.size = Vector3.ZERO
				tri_aabb = tri_aabb.expand(vertices[tri[1]])
				tri_aabb = tri_aabb.expand(vertices[tri[2]])
				triangles[i]["centroid"] = tri_aabb.position + tri_aabb.size * 0.5
		
		# Split the triangles between the 6 axes directions.
		var left_nodes := [[], [], []]
		var right_nodes := [[], [], []]
		for i in triangles.size() :
			for j in 3 :
				if triangles[i].centroid[j] < center[j]:
					left_nodes[j].append(i)
				else:
					right_nodes[j].append(i)
		
		# Check which splits have failed.
		# If they all have, we can't split any furthe.
		var split_failed = [false, false, false]
		split_failed[0] = left_nodes[0].empty() or right_nodes[0].empty()
		split_failed[1] = left_nodes[1].empty() or right_nodes[1].empty()
		split_failed[2] = left_nodes[2].empty() or right_nodes[2].empty()
		if split_failed[0] and split_failed[1] and split_failed[2]:
			root._node_data[-1] = triangles.size()
			for tri in triangles :
				var vert_a : Vector3 = vertices[tri[0]]
				var vert_b : Vector3 = vertices[tri[1]]
				var vert_c : Vector3 = vertices[tri[2]]
				_append_4(root._node_data, vert_a.x, vert_a.y, vert_a.z)
				_append_4(root._node_data, vert_b.x, vert_b.y, vert_b.z)
				_append_4(root._node_data, vert_c.x, vert_c.y, vert_c.z)
			if root == self:
				_finalize_data()
			return level
		
		var split_order := [0, 1, 2]
		split_order.sort_custom(self, "_sort_by_extents")
		
		var left_triangles := []
		var right_triangles := []
		for split in split_order :
			if not split_failed[split]:
				for i in left_nodes[split] :
					left_triangles.append(triangles[i])
				for i in right_nodes[split] :
					right_triangles.append(triangles[i])
				break
		if root != self:
			triangles.clear()
		
		_append_4(root._node_data)
		
		# Generate the new children nodes.
		left_node = BVHNode.new()
		left_node.root = root
		left_node.parent = self
		left_node.level = level + 1
		left_node.vertices = vertices
		left_node.triangles = left_triangles
		var left_max_level := left_node.generate()
		root._node_data[data_offset + 8] = root._node_ids[left_node]
		
		right_node = BVHNode.new()
		right_node.root = root
		right_node.parent = self
		right_node.level = level + 1
		right_node.vertices = vertices
		right_node.triangles = right_triangles
		var right_max_level := right_node.generate()
		root._node_data[data_offset + 9] = root._node_ids[right_node]
		
		if root == self:
			_finalize_data()
		return int(max(left_max_level, right_max_level))
		
	# This function is a one-to-one translation of the shader function.
	# Not really used in this project, but makes debugging much easier.
	func traverse(ray_start : Vector3, ray_dir : Vector3) -> float:
		if _data.empty():
			return 65536.0
		
		var offset_to_nodes : int = _get_data(0)[0]
		var root_data_0 = _get_data(_get_data(1)[0] + offset_to_nodes)
		var root_data_1 = _get_data(_get_data(1)[0] + offset_to_nodes + 1)
		
		var min_root := Vector3(root_data_0[0], root_data_0[1], root_data_0[2])
		var max_root := Vector3(root_data_1[0], root_data_1[1], root_data_1[2])
		
		var t := _intersect_aabb(ray_start, ray_dir, min_root, max_root)
		if t == -1:
			return 65536.0
		
		var prev_hit := t
		# Set to large number.
		t = 65536.0
		
		var stack_point := 0
		# ivec3
		var node_stack := []
		node_stack.resize(128)
		
		var curr_node_idx := 0
		var moving_up := false
		
		for i in 1024 :
			if moving_up and stack_point <= 0:
				break
			var node_data_off = _get_data(
						DATA_HEADER_SIZE + curr_node_idx)[0] + offset_to_nodes
			var node_data_0 = _get_data(node_data_off)
			var node_data_1 = _get_data(node_data_off + 1)
			var node_level = node_data_0[3]
			
			if not moving_up : # Moving down node hierarcy
				if node_data_1[3] > 0 : # Is a leaf noe
					for j in range(node_data_off + 2,
							node_data_off + 2 + node_data_1[3] * 3, 3) :
						var tri_a = _get_data(j)
						var tri_b = _get_data(j + 1)
						var tri_c = _get_data(j + 2)
						var tri_t = Geometry.ray_intersects_triangle(ray_start,
							ray_dir, Vector3(tri_a[0], tri_a[1], tri_a[2]),
							Vector3(tri_b[0], tri_b[1], tri_b[2]),
							Vector3(tri_c[0], tri_c[1], tri_c[2])
						)
						if tri_t:
							tri_t = tri_t.distance_to(ray_start)
							t = min(t, tri_t)
					
					stack_point -= 1
					if stack_point <= 0:
						break
					if node_stack[stack_point][1] == level:
						# next node in stack is sibling.
						if t < node_stack[stack_point][0]:
							# no chance to get better hit from sibling.
							stack_point -= 1
							moving_up = true
					else:
						moving_up = true
					prev_hit = node_stack[stack_point][0]
					curr_node_idx = node_stack[stack_point][2]
				else:
					# Push self onto stack.
					node_stack[stack_point] = Vector3(prev_hit, node_level,
							curr_node_idx)
					stack_point += 1
					
					var child_indices = _get_data(node_data_off + 2)
					var left_data_off = _get_data(1 + child_indices[0])[0] +\
							offset_to_nodes
					var left_data_0 = _get_data(left_data_off)
					var left_data_1 = _get_data(left_data_off + 1)
					var right_data_off = _get_data(1 + child_indices[1])[0] +\
							offset_to_nodes
					var right_data_0 = _get_data(right_data_off)
					var right_data_1 = _get_data(right_data_off + 1)
					
					var min_left = Vector3(left_data_0[0], left_data_0[1],
							left_data_0[2])
					var max_left = Vector3(left_data_1[0], left_data_1[1],
							left_data_1[2])
					var min_right = Vector3(right_data_0[0], right_data_0[1],
							right_data_0[2])
					var max_right = Vector3(right_data_1[0], right_data_1[1],
							right_data_1[2])
					
					var t_left = _intersect_aabb(ray_start, ray_dir, min_left,
							max_left, true)
					var t_right = _intersect_aabb(ray_start, ray_dir, min_right,
							max_right, true)
					
					if t_right == -1 and t_left != -1:
						# Only left node hit.
						prev_hit = t_left
						curr_node_idx = child_indices[0]
					elif t_left == -1 and t_right != -1:
						# Only right node hit.
						prev_hit = t_right
						curr_node_idx = child_indices[1]
					elif t_left < t_right and t_left != -1:
						# Left node hits closer.
						node_stack[stack_point] = Vector3(t_right,
								right_data_0[3], child_indices[1])
						stack_point += 1
						prev_hit = t_left
						curr_node_idx = child_indices[0]
					elif t_right <= t_left and t_right != -1:
						# Right node hits closer.
						node_stack[stack_point] = Vector3(t_left,
								left_data_0[3], child_indices[0])
						stack_point += 1
						prev_hit = t_right
						curr_node_idx = child_indices[1]
					else: # no hit
						stack_point -= 2
						if stack_point <= 0:
							break
						if node_stack[stack_point][1] == node_level:
							# Next node in stack is sibling.
							if t < node_stack[stack_point][0]:
								# No chance to get better hit from sibling.
								stack_point -= 1
								moving_up = true
						else:
							moving_up = true
						prev_hit = node_stack[max(stack_point, 0)][0]
						curr_node_idx = node_stack[max(stack_point, 0)][2]
			else:
				# Moving up hierarchy.
				stack_point -= 1
				if stack_point <= 0:
					break
				if node_stack[stack_point][1] == node_level:
					# Next node in stack is sibling.
					if t < node_stack[stack_point][0]:
						# No chance to get better hit from sibling.
						stack_point -= 1
					else:
						moving_up = false
				prev_hit = node_stack[max(stack_point, 0)][0]
				curr_node_idx = node_stack[max(stack_point, 0)][2]
		return t
	
	func calculate_aabb() -> void:
		aabb.position = vertices[triangles[0][0]]
		aabb.size = Vector3.ZERO
		for tri in triangles :
			for j in 3 :
				aabb = aabb.expand(vertices[tri[j]])
		center = aabb.position + aabb.size * 0.5
	
	func debug_aabb() -> Array:
		var aabbs := []
		
		var aabb_shape := CollisionShape.new()
		aabb_shape.name = "BVHNode-" + str(root._node_ids[self])
		
		aabb_shape.shape = BoxShape.new()
		(aabb_shape.shape as BoxShape).extents = aabb.size * 0.5
		aabb_shape.translation = aabb.position + aabb.size * 0.5
		aabbs.append(aabb_shape)
		
		if left_node:
			var left_aabbs := left_node.debug_aabb()
			aabbs += left_aabbs
			aabb_shape.add_child(left_aabbs[0])
			left_aabbs[0].translation -= aabb_shape.translation
		if right_node:
			var right_aabbs := right_node.debug_aabb()
			aabbs += right_aabbs
			aabb_shape.add_child(right_aabbs[0])
			right_aabbs[0].translation -= aabb_shape.translation
		return aabbs
	
	func _get_data(index : int) -> Array:
		return [_data[index * 4], _data[index * 4 + 1], _data[index * 4 + 2],
				_data[index * 4 + 3]]
	
	# This is faster than appending a whole array to the other array.
	func _append_4(array : Array, val0 = 0, val1 = 0, val2 = 0,
			val3 = 0) -> void:
		array.append(val0)
		array.append(val1)
		array.append(val2)
		array.append(val3)

	# All the stuff in _data and _node_data are appended and put into image.
	func _finalize_data() -> void:
		_data[0] = _node_ids.size() + DATA_HEADER_SIZE
		
		_data += _node_data
		var data_size := int(_data.size() / 4.0)
		var img_width : int = int(min(data_size, 16384))
		var img_height : int = int(data_size / 16384.0 + 1)
		
		image = Image.new()
		image.create(img_width, img_height, false, Image.FORMAT_RGBAF)
		image.lock()
		var i = 0
		for y in img_height :
			for x in img_width :
				if i > data_size - 1:
					break
				image.set_pixel(x, y, Color(_data[i * 4], _data[i * 4 + 1],
						_data[i * 4 + 2], _data[i * 4 + 3]))
				i += 1
		image.unlock()
	
	func _sort_by_extents(a : int, b : int) -> bool:
		return aabb.size[a] > aabb.size[b]
	
	static func _intersect_aabb(ray_origin : Vector3, ray_dir : Vector3,
			box_min : Vector3, box_max : Vector3, solid :=false) -> float:
		var tMin := (box_min - ray_origin) / ray_dir
		var tMax := (box_max - ray_origin) / ray_dir
		var t1 := Vector3(min(tMin.x, tMax.x), min(tMin.y, tMax.y),
				min(tMin.z, tMax.z))
		var t2 := Vector3(max(tMin.x, tMax.x), max(tMin.y, tMax.y),
				max(tMin.z, tMax.z))
		var tNear := max(max(t1.x, t1.y), t1.z)
		var tFar := min(min(t2.x, t2.y), t2.z)
		
		if tNear > tFar or (tFar < 0.0 and tNear < 0.0):
			return -1.0
		
		if tNear < 0.0:
			var temp := tNear
			tNear = tFar
			tFar = temp
			if solid:
				return 0.0
		return tNear
