@tool
class_name SevenSegmentDigitMesh
extends ArrayMesh


const ROOT_2 := sqrt(2)

@export var size: Vector2 = Vector2(0.3, 0.5):
	get: return size
	set(value):
		if size == value:
			return
		size = value
		if Engine.is_editor_hint():
			rebuild()
@export var segment_thickness: float = 0.05:
	get: return segment_thickness
	set(value):
		if segment_thickness == value:
			return
		segment_thickness = value
		if Engine.is_editor_hint():
			rebuild()
@export var segment_gap: float = 0.015:
	get: return segment_gap
	set(value):
		if segment_gap == value:
			return
		segment_gap = value
		if Engine.is_editor_hint():
			rebuild()
@export_range(0.0, 1.0, 0.01) var corner_fill: float = 0.5:
	get: return corner_fill
	set(value):
		if corner_fill == value:
			return
		corner_fill = value
		if Engine.is_editor_hint():
			rebuild()
@export_range(0.0, 1.0, 0.01) var side_fill: float = 0.0:
	get: return side_fill
	set(value):
		if side_fill == value:
			return
		side_fill = value
		if Engine.is_editor_hint():
			rebuild()
@export_range(-1.0, 1.0) var slant: float = 0.0:
	get: return slant
	set(value):
		if slant == value:
			return
		slant = value
		if Engine.is_editor_hint():
			rebuild()


func rebuild() -> void:

	if get_surface_count() == 0:

		var verts := PackedVector3Array()
		verts.resize(7 * 6)
		_update_verts(verts)

		var normals := PackedVector3Array()
		normals.resize(verts.size())
		normals.fill(Vector3.BACK)

		var uvs := PackedVector2Array()
		uvs.resize(verts.size())
		for i in uvs.size():
			var seg_idx := floori(i / 6.0)
			uvs[i] = Vector2(seg_idx + 0.001, 0)

		var indices := PackedInt32Array()
		indices.resize(7 * 12)
		for i in 7:
			var io := i * 6
			var iio := i * 12
			indices[iio + 0] = io + 0
			indices[iio + 1] = io + 2
			indices[iio + 2] = io + 1
			indices[iio + 3] = io + 1
			indices[iio + 4] = io + 2
			indices[iio + 5] = io + 3
			indices[iio + 6] = io + 3
			indices[iio + 7] = io + 2
			indices[iio + 8] = io + 4
			indices[iio + 9] = io + 3
			indices[iio + 10] = io + 4
			indices[iio + 11] = io + 5

		var arrays := []
		arrays.resize(ARRAY_MAX)
		arrays[ARRAY_VERTEX] = verts
		arrays[ARRAY_NORMAL] = normals
		arrays[ARRAY_TEX_UV] = uvs
		arrays[ARRAY_INDEX] = indices
		add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)

	else:

		var arrays := surface_get_arrays(0)
		var verts: PackedVector3Array = arrays[ARRAY_VERTEX]
		_update_verts(verts)
		surface_update_vertex_region(0, 0, verts.to_byte_array())

		var size := Vector3(size.x + absf(slant) * size.y, size.y, 0)
		custom_aabb = AABB(-size / 2, size)


func _update_verts(verts: PackedVector3Array) -> void:

	var e := Vector2((size.x - segment_thickness) / 2, (size.y - segment_thickness) / 2)
	var d := segment_gap / ROOT_2
	var w := e.x - d
	var h := e.y / 2 - d

	_update_segment_verts(verts, 0, Vector2(0, e.y), w, false)
	_update_segment_verts(verts, 1, Vector2(e.x, e.y / 2), h, true)
	_update_segment_verts(verts, 2, Vector2(e.x, -e.y / 2), h, true)
	_update_segment_verts(verts, 3, Vector2(0, -e.y), w, false)
	_update_segment_verts(verts, 4, Vector2(-e.x, -e.y / 2), h, true)
	_update_segment_verts(verts, 5, Vector2(-e.x, e.y / 2), h, true)
	_update_segment_verts(verts, 6, Vector2(0, 0), w, false)

	if corner_fill > 0:
		var a := segment_thickness * corner_fill
		var b := a / 2
		# Segment A
		verts[0] += Vector3(-b, b, 0)
		verts[2] += Vector3(-a, 0, 0)
		verts[4] += Vector3(a, 0, 0)
		verts[5] += Vector3(b, b, 0)
		# Segment B
		verts[6] += Vector3(b, b, 0)
		verts[8] += Vector3(0, a, 0)
		# Segment C
		verts[16] += Vector3(0, -a, 0)
		verts[17] += Vector3(b, -b, 0)
		# Segment D
		verts[18] += Vector3(-b, -b, 0)
		verts[19] += Vector3(-a, 0, 0)
		verts[21] += Vector3(a, 0, 0)
		verts[23] += Vector3(b, -b, 0)
		# Segment E
		verts[27] += Vector3(0, -a, 0)
		verts[29] += Vector3(-b, -b, 0)
		# Segment F
		verts[30] += Vector3(-b, b, 0)
		verts[31] += Vector3(0, a, 0)

	if side_fill > 0:
		var a := segment_thickness * side_fill
		var b := a / 2
		if side_fill < 1:
			# Segment B
			verts[9] += Vector3(0, b, 0)
			verts[11] += Vector3(b, 0, 0)
			# Segment C
			verts[12] += Vector3(b, 0, 0)
			verts[13] += Vector3(0, -b, 0)
			# Segment E
			verts[24] += Vector3(-b, 0, 0)
			verts[26] += Vector3(0, -b, 0)
			# Segment F
			verts[34] += Vector3(0, b, 0)
			verts[35] += Vector3(-b, 0, 0)
			# Segment G
			verts[36] += Vector3(-b, 0, 0)
			verts[37] += Vector3(-b, 0, 0)
			verts[38] += Vector3(-b, 0, 0)
			verts[39] += Vector3(b, 0, 0)
			verts[40] += Vector3(b, 0, 0)
			verts[41] += Vector3(b, 0, 0)
		# Segment B
		verts[10] += Vector3(0, -b, 0)
		# Segment C
		verts[14] += Vector3(0, b, 0)
		# Segment E
		verts[25] += Vector3(0, b, 0)
		# Segment F
		verts[33] += Vector3(0, -b, 0)

	if not is_zero_approx(slant):
		for i in verts.size():
			var p := verts[i]
			p.x += p.y * slant
			verts[i] = p


func _update_segment_verts(
		verts: PackedVector3Array,
		seg_idx: int,
		center: Vector2,
		half_length: float,
		vertical: bool) -> void:

	var io := seg_idx * 6
	var l1 := half_length
	var t := segment_thickness / 2
	var l2 := l1 - t
	var c := center

	if vertical:
		verts[io + 0] = Vector3(c.x, c.y + l1, 0)
		verts[io + 1] = Vector3(c.x - t, c.y + l2, 0)
		verts[io + 2] = Vector3(c.x + t, c.y + l2, 0)
		verts[io + 3] = Vector3(c.x - t, c.y - l2, 0)
		verts[io + 4] = Vector3(c.x + t, c.y - l2, 0)
		verts[io + 5] = Vector3(c.x, c.y - l1, 0)
	else:
		verts[io + 0] = Vector3(c.x - l1, c.y, 0)
		verts[io + 1] = Vector3(c.x - l2, c.y - t, 0)
		verts[io + 2] = Vector3(c.x - l2, c.y + t, 0)
		verts[io + 3] = Vector3(c.x + l2, c.y - t, 0)
		verts[io + 4] = Vector3(c.x + l2, c.y + t, 0)
		verts[io + 5] = Vector3(c.x + l1, c.y, 0)
