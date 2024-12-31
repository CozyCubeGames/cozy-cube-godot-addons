@tool
class_name TwentySevenPatchMesh
extends ArrayMesh


@export var input_mesh: ArrayMesh:
	get: return input_mesh
	set(value):
		if value == input_mesh:
			return
		if Engine.is_editor_hint():
			if input_mesh:
				input_mesh.changed.disconnect(rebuild)
		input_mesh = value
		if Engine.is_editor_hint():
			rebuild()
			if input_mesh:
				input_mesh.changed.connect(rebuild)
@export var input_size: Vector3 = Vector3(1, 1, 1):
	get: return input_size
	set(value):
		if value == input_size:
			return
		input_size = Vector3(maxf(value.x, 0.001), maxf(value.y, 0.001), maxf(value.z, 0.001))
		if Engine.is_editor_hint():
			remap_vertices()
@export var output_size: Vector3 = Vector3(1, 1, 1):
	get: return output_size
	set(value):
		if value == output_size:
			return
		output_size = Vector3(maxf(value.x, 0.001), maxf(value.y, 0.001), maxf(value.z, 0.001))
		if Engine.is_editor_hint():
			remap_vertices()
@export var right_margin: float = 0.25:
	get: return right_margin
	set(value):
		if value == right_margin:
			return
		right_margin = value
		if Engine.is_editor_hint():
			remap_vertices()
@export var left_margin: float = 0.25:
	get: return left_margin
	set(value):
		if value == left_margin:
			return
		left_margin = value
		if Engine.is_editor_hint():
			remap_vertices()
@export var top_margin: float = 0.25:
	get: return top_margin
	set(value):
		if value == top_margin:
			return
		top_margin = value
		if Engine.is_editor_hint():
			remap_vertices()
@export var bottom_margin: float = 0.25:
	get: return bottom_margin
	set(value):
		if value == bottom_margin:
			return
		bottom_margin = value
		if Engine.is_editor_hint():
			remap_vertices()
@export var front_margin: float = 0.25:
	get: return front_margin
	set(value):
		if value == front_margin:
			return
		front_margin = value
		if Engine.is_editor_hint():
			remap_vertices()
@export var back_margin: float = 0.25:
	get: return back_margin
	set(value):
		if value == back_margin:
			return
		back_margin = value
		if Engine.is_editor_hint():
			remap_vertices()


func rebuild() -> void:

	clear_surfaces()
	clear_blend_shapes()

	if input_mesh:

		for surf_idx in input_mesh.get_surface_count():
			var arrays := input_mesh.surface_get_arrays(surf_idx)
			add_surface_from_arrays(
				input_mesh.surface_get_primitive_type(surf_idx),
				arrays)
			surface_set_name(surf_idx, input_mesh.surface_get_name(surf_idx))
			surface_set_material(surf_idx, input_mesh.surface_get_material(surf_idx))

		remap_vertices()

	else:

		var arrays := []
		arrays.resize(ARRAY_MAX)
		arrays[ARRAY_VERTEX] = PackedVector3Array([Vector3.ZERO])
		arrays[ARRAY_INDEX] = PackedInt32Array([0, 0, 0])
		add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		return


func remap_vertices() -> void:

	if not input_mesh:
		return

	var input_ext := input_size / 2
	var input_center_min := -input_ext + Vector3(left_margin, bottom_margin, back_margin)
	var input_center_max := input_ext - Vector3(right_margin, top_margin, front_margin)

	var output_ext := output_size / 2
	var output_center_min := -output_ext + Vector3(left_margin, bottom_margin, back_margin)
	var output_center_max := output_ext - Vector3(right_margin, top_margin, front_margin)

	for surf_idx in input_mesh.get_surface_count():

		var arrays := input_mesh.surface_get_arrays(surf_idx)
		var verts: PackedVector3Array = arrays[ARRAY_VERTEX]

		for i in verts.size():

			var p := verts[i]

			var x_patch: int = 0
			var y_patch: int = 0
			var z_patch: int = 0
			if p.x >= input_center_max.x:
				x_patch = 1
			elif p.x <= input_center_min.x:
				x_patch = -1
			if p.y >= input_center_max.y:
				y_patch = 1
			elif p.y <= input_center_min.y:
				y_patch = -1
			if p.z >= input_center_max.z:
				z_patch = 1
			elif p.z <= input_center_min.z:
				z_patch = -1

			match x_patch:
				1: p.x = output_ext.x + p.x - input_ext.x
				-1: p.x = -output_ext.x + p.x + input_ext.x
				0: p.x = remap(p.x, input_center_min.x, input_center_max.x, output_center_min.x, output_center_max.x)
			match y_patch:
				1: p.y = output_ext.y + p.y - input_ext.y
				-1: p.y = -output_ext.y + p.y + input_ext.y
				0: p.y = remap(p.y, input_center_min.y, input_center_max.y, output_center_min.y, output_center_max.y)
			match z_patch:
				1: p.z = output_ext.z + p.z - input_ext.z
				-1: p.z = -output_ext.z + p.z + input_ext.z
				0: p.z = remap(p.z, input_center_min.z, input_center_max.z, output_center_min.z, output_center_max.z)

			verts[i] = p

		surface_update_vertex_region(surf_idx, 0, verts.to_byte_array())
		custom_aabb = _get_aabb()


func _get_aabb() -> AABB:

	if input_mesh:
		var aabb := input_mesh.get_aabb()
		var size_ratio := output_size / input_size
		aabb.position *= size_ratio
		aabb.size *= size_ratio
		return aabb
	else:
		return AABB(Vector3.ZERO, Vector3.ZERO)
