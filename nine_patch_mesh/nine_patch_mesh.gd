@tool
class_name NinePatchMesh
extends ArrayMesh


@export var input_mesh: ArrayMesh:
	get: return input_mesh
	set(value):
		if value == input_mesh:
			return
		input_mesh = value
		if Engine.is_editor_hint():
			rebuild()
@export var input_size: Vector2 = Vector2(1, 1):
	get: return input_size
	set(value):
		if value == input_size:
			return
		input_size = value
		if Engine.is_editor_hint():
			remap_vertices()
@export var output_size: Vector2 = Vector2(1, 1):
	get: return output_size
	set(value):
		if value == output_size:
			return
		output_size = value
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
	var input_min := Vector2(-input_ext.x, -input_ext.y)
	var input_max := Vector2(input_ext.x, input_ext.y)
	var input_center_min := input_min + Vector2(left_margin, bottom_margin)
	var input_center_max := input_max - Vector2(right_margin, top_margin)

	var output_ext := output_size / 2
	var output_min := Vector2(-output_ext.x, -output_ext.y)
	var output_max := Vector2(output_ext.x, output_ext.y)
	var output_center_min := output_min + Vector2(left_margin, bottom_margin)
	var output_center_max := output_max - Vector2(right_margin, top_margin)

	for surf_idx in input_mesh.get_surface_count():

		var arrays := input_mesh.surface_get_arrays(surf_idx)
		var verts: PackedVector3Array = arrays[ARRAY_VERTEX]

		for i in verts.size():

			var p := verts[i]

			var x_patch: int = 0
			var y_patch: int = 0
			if p.x >= input_center_max.x:
				x_patch = 1
			elif p.x <= input_center_min.x:
				x_patch = -1
			if p.y >= input_center_max.y:
				y_patch = 1
			elif p.y <= input_center_min.y:
				y_patch = -1

			match x_patch:
				1: p.x = output_max.x + p.x - input_max.x
				-1: p.x = output_min.x + p.x - input_min.x
				0: p.x = remap(p.x, input_center_min.x, input_center_max.x, output_center_min.x, output_center_max.x)
			match y_patch:
				1: p.y = output_max.y + p.y - input_max.y
				-1: p.y = output_min.y + p.y - input_min.y
				0: p.y = remap(p.y, input_center_min.y, input_center_max.y, output_center_min.y, output_center_max.y)

			verts[i] = p

		surface_update_vertex_region(surf_idx, 0, verts.to_byte_array())
