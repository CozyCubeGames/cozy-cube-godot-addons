@tool
class_name ControlProxy3D
extends MeshInstance3D


enum ThicknessGrowDirection { OUTWARD, INWARD, BOTH }

const DEFAULT_TEX_PARAM: StringName = "vp_tex"

@export var control: Control:
	set(value):
		if control == value:
			return
		if control:
			control.visibility_changed.disconnect(_on_control_visibility_changed)
			control.item_rect_changed.disconnect(_on_control_rect_changed)
		control = value
		if control:
			control.visibility_changed.connect(_on_control_visibility_changed)
			control.item_rect_changed.connect(_on_control_rect_changed)
		if is_node_ready():
			mesh = ArrayMesh.new()
			rebuild()
@export var pixels_per_meter: float = 256:
	set(value):
		if pixels_per_meter == value:
			return
		pixels_per_meter = value
		if is_node_ready():
			rebuild()
@export_range(0.0, 1.0, 0.001) var corner_radius: float = 0.0:
	set(value):
		if corner_radius == value:
			return
		corner_radius = value
		if Engine.is_editor_hint() and is_node_ready():
			rebuild()
@export_range(1, 16, 1) var corner_segments: int = 4:
	set(value):
		if corner_segments == value:
			return
		corner_segments = value
		if Engine.is_editor_hint() and is_node_ready():
			rebuild()
@export_range(0.0, 1.0, 0.001) var thickness: float = 0.0:
	set(value):
		if thickness == value:
			return
		thickness = value
		if Engine.is_editor_hint() and is_node_ready():
			rebuild()
@export var thickness_grow_direction: ThicknessGrowDirection = ThicknessGrowDirection.OUTWARD:
	set(value):
		if thickness_grow_direction == value:
			return
		thickness_grow_direction = value
		if Engine.is_editor_hint() and is_node_ready():
			rebuild()
@export_range(-1.0, 1.0, 0.001) var margin: float = 0.0:
	set(value):
		if margin == value:
			return
		margin = value
		if Engine.is_editor_hint() and is_node_ready():
			rebuild()
@export var shader: Shader:
	set(value):
		if shader == value:
			return
		shader = value
		if Engine.is_editor_hint() and is_node_ready():
			_refresh_material()
@export var tex_param: StringName = DEFAULT_TEX_PARAM:
	set(value):
		if tex_param == value:
			return
		tex_param = value
		if Engine.is_editor_hint() and is_node_ready():
			_refresh_material()

var _material: ShaderMaterial

static var _arrays: Array
static var _verts: PackedVector3Array
static var _uvs: PackedVector2Array
static var _normals: PackedVector3Array
static var _colors: PackedColorArray
static var _indices: PackedInt32Array


func _ready() -> void:

	if not mesh:
		mesh = ArrayMesh.new()
		_material = null

	if not _material:
		if mesh.get_surface_count() > 0:
			_material = mesh.surface_get_material(0)
		if not _material:
			_material = ShaderMaterial.new()

	if mesh.get_surface_count() > 0:
		mesh.surface_set_material(0, _material)

	_refresh_material()

	if is_instance_valid(control):
		visible = control.visible


func get_size_3d() -> Vector3:

	if control:
		return Vector3(
				control.size.x / pixels_per_meter + margin * 2,
				control.size.y / pixels_per_meter + margin * 2,
				thickness)
	else:
		return Vector3.ZERO


func local_to_control_point(p: Vector3) -> Vector2:

	if control:
		return Vector2(p.x, -p.y) * pixels_per_meter + control.size / 2
	else:
		return Vector2.ZERO


func world_to_control_point(p: Vector3) -> Vector2:

	return local_to_control_point(to_local(p))


func control_to_local_point(p: Vector2) -> Vector3:

	if control:
		p = (p - control.size / 2) / pixels_per_meter
		return Vector3(p.x, -p.y, 0)
	else:
		return Vector3.ZERO


func control_to_world_point(p: Vector2) -> Vector3:

	return to_global(control_to_local_point(p))


func rebuild() -> void:

	if not control or not control.is_inside_tree():
		return

	var vp := control.get_viewport()
	var vp_size := vp.get_visible_rect().size
	var c_pos := control.global_position
	var c_pivot := control.pivot_offset
	var c_size := control.size
	var size := get_size_3d()
	var extents := size / 2
	var extents_with_margin := Vector2(maxf(0, extents.x + margin), maxf(0, extents.y + margin))
	var r := minf(corner_radius, minf(extents_with_margin.x, extents_with_margin.y))
	var inner_extents := Vector2(maxf(0, extents_with_margin.x - r), maxf(0, extents_with_margin.y - r))

	var border_vert_count := 0
	var border_tri_count := 0
	var side_tri_count := 0
	var face_vert_count := 0
	if r > 0:
		border_vert_count = (corner_segments + 1) * 4
		face_vert_count = 4 + border_vert_count
		border_tri_count = (corner_segments + 2) * 4
	else:
		border_vert_count = 4
		face_vert_count = 4
	var face_tri_count := 2 + border_tri_count
	var total_vert_count := face_vert_count * 2
	var total_tri_count := face_tri_count * 2
	if thickness > 0:
		total_vert_count *= 2
		side_tri_count = 8
		if r > 0:
			side_tri_count += (corner_segments * 2) * 4
		total_tri_count += side_tri_count
	var total_index_count := total_tri_count * 3

	if _arrays.is_empty():
		_arrays.resize(Mesh.ARRAY_MAX)
		_arrays[Mesh.ARRAY_VERTEX] = _verts
		_arrays[Mesh.ARRAY_TEX_UV] = _uvs
		_arrays[Mesh.ARRAY_NORMAL] = _normals
		_arrays[Mesh.ARRAY_COLOR] = _colors
		_arrays[Mesh.ARRAY_INDEX] = _indices

	_verts.resize(total_vert_count)
	_uvs.resize(total_vert_count)
	_normals.resize(total_vert_count)
	_colors.resize(total_vert_count)
	_indices.resize(total_index_count)

	# Front face inner quad
	var front_z: float
	match thickness_grow_direction:
		ThicknessGrowDirection.OUTWARD: front_z = thickness
		ThicknessGrowDirection.INWARD: front_z = 0
		ThicknessGrowDirection.BOTH: front_z = thickness / 2
	_verts[0] = Vector3(-inner_extents.x, inner_extents.y, front_z)
	_verts[1] = Vector3(inner_extents.x, inner_extents.y, front_z)
	_verts[2] = Vector3(inner_extents.x, -inner_extents.y, front_z)
	_verts[3] = Vector3(-inner_extents.x, -inner_extents.y, front_z)
	_indices[0] = 0
	_indices[1] = 1
	_indices[2] = 2
	_indices[3] = 2
	_indices[4] = 3
	_indices[5] = 0

	# Face normals

	for i in face_vert_count:
		_normals[i] = Vector3.BACK
		_normals[face_vert_count + i] = Vector3.FORWARD

	# Front face border and side normals
	if r > 0:
		var q_inc := -PI / 2 / corner_segments
		for corner_idx in 4:
			var start_index := 4 + corner_idx * (corner_segments + 1)
			var start_tri_index := 2 + corner_idx * (corner_segments + 2)
			var start_index_index := start_tri_index * 3
			var start_q := PI - corner_idx * (PI / 2)
			var side_start_index := face_vert_count * 2 + start_index
			var o := _verts[corner_idx]
			for i in (corner_segments + 1):
				var q := start_q + i * q_inc
				var dir := Vector3(cos(q), sin(q), 0)
				var seg_start_index_index := start_index_index + i * 3
				var index := start_index + i
				_verts[index] = o + dir * r
				if thickness > 0:
					_normals[side_start_index + i] = dir
					_normals[side_start_index + face_vert_count + i] = dir
				if i < corner_segments:
					_indices[seg_start_index_index + 0] = index
					_indices[seg_start_index_index + 1] = index + 1
					_indices[seg_start_index_index + 2] = corner_idx
				else:
					var p0 := index
					var p1 := index + 1
					var p2 := corner_idx + 1
					var p3 := corner_idx
					if corner_idx == 3:
						p1 = 4
						p2 = 0
					_indices[seg_start_index_index + 0] = p0
					_indices[seg_start_index_index + 1] = p1
					_indices[seg_start_index_index + 2] = p2
					_indices[seg_start_index_index + 3] = p2
					_indices[seg_start_index_index + 4] = p3
					_indices[seg_start_index_index + 5] = p0

	# Back face
	var face_index_count := face_tri_count * 3
	for i in face_vert_count:
		var front_p := _verts[i]
		var back_p := Vector3(front_p.x, front_p.y, front_p.z - thickness)
		_verts[face_vert_count + i] = back_p
		_normals[face_vert_count + i] = Vector3.FORWARD
	for i in face_index_count:
		_indices[face_index_count + i] = _indices[face_index_count - 1 - i] + face_vert_count

	# Sides
	if thickness > 0:
		for i in face_vert_count:
			var front_p := _verts[i]
			var back_p := _verts[face_vert_count + i]
			_verts[face_vert_count * 2 + i] = front_p
			_verts[face_vert_count * 3 + i] = back_p
		for i in border_vert_count:
			var side_front_start_index := face_vert_count * 2
			var side_back_start_index := face_vert_count * 3
			if r > 0:
				side_front_start_index += 4
				side_back_start_index += 4
			var i_next := (i + 1) % border_vert_count
			var front_index0 := side_front_start_index + i
			var back_index0 := side_back_start_index + i
			var front_index1 := side_front_start_index + i_next
			var back_index1 := side_back_start_index + i_next
			var side_start_index_index := face_index_count * 2 + i * 6
			_indices[side_start_index_index + 0] = back_index0
			_indices[side_start_index_index + 1] = back_index1
			_indices[side_start_index_index + 2] = front_index1
			_indices[side_start_index_index + 3] = front_index1
			_indices[side_start_index_index + 4] = front_index0
			_indices[side_start_index_index + 5] = back_index0


	# Colors
	_colors.fill(Color.WHITE)
	for i in 4:
		_colors[i] = Color.BLACK
		_colors[face_vert_count + i] = Color.BLACK

	# UVs
	for i in total_vert_count:
		var p := _verts[i]
		var cp := local_to_control_point(p)
		_uvs[i] = (c_pos + cp) / vp_size

	mesh.clear_surfaces()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, _arrays)
	mesh.surface_set_material(0, _material)

	_refresh_material()
	visible = control.visible


func push_input(event: InputEvent) -> void:

	if control and control.is_inside_tree():
		control.get_viewport().push_input(event)


func push_unhandled_input(event: InputEvent) -> void:

	if control and control.is_inside_tree():
		control.get_viewport().push_unhandled_input(event)


func push_text_input(text: String) -> void:

	if control and control.is_inside_tree():
		control.get_viewport().push_text_input(text)


func _refresh_material() -> void:

	var vp_tex := control.get_viewport().get_texture() if (control and control.is_inside_tree()) else null
	_material.shader = shader if shader else _get_default_shader()
	_material.set_shader_parameter(tex_param, vp_tex)


func _on_control_visibility_changed() -> void:

	if control:
		visible = control.visible


func _on_control_rect_changed() -> void:

	if is_node_ready():
		rebuild()


static func _get_default_shader() -> Shader:

	return load("res://addons/control_proxies/control_proxy_unlit_solid.gdshader")
