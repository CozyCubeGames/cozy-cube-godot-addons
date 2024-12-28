@tool

class_name Line3D
extends MeshInstance3D


enum TextureTileMode { RATIO, DISTANCE }
enum BillboardMode { NONE, VIEW, Z }
enum MaterialType {
	SOLID,
	SOLID_UNLIT,
	MIX,
	MIX_UNLIT,
	ADD,
	CUSTOM }


@export_range(0.0, 1.0) var width: float = 0.05:
	get: return width
	set(value):
		if width == value:
			return
		width = value
		if _auto_rebuild and Engine.is_editor_hint():
			rebuild()
@export var width_curve: Curve:
	get: return width_curve
	set(value):
		if width_curve == value:
			return
		if width_curve:
			width_curve.changed.disconnect(_on_child_resource_changed)
		width_curve = value
		if width_curve:
			width_curve.changed.connect(_on_child_resource_changed)
		if _auto_rebuild and Engine.is_editor_hint():
			rebuild()
@export var color: Color = Color.WHITE:
	get: return color
	set(value):
		if color == value:
			return
		color = value
		if _auto_rebuild and Engine.is_editor_hint():
			rebuild()
@export var gradient: Gradient:
	get: return gradient
	set(value):
		if gradient == value:
			return
		if gradient:
			gradient.changed.disconnect(_on_child_resource_changed)
		gradient = value
		if gradient:
			gradient.changed.connect(_on_child_resource_changed)
		if _auto_rebuild and Engine.is_editor_hint():
			rebuild()
@export var use_global_space: bool = false:
	get: return use_global_space
	set(value):
		if use_global_space == value:
			return
		use_global_space = value
		set_notify_transform(use_global_space)
		if _auto_rebuild and Engine.is_editor_hint():
			rebuild()
@export var billboard_mode: BillboardMode = BillboardMode.VIEW:
	get: return billboard_mode
	set(value):
		if billboard_mode == value:
			return
		billboard_mode = value
		notify_property_list_changed()
		if _auto_rebuild and Engine.is_editor_hint():
			rebuild()
@export var texture_tile_mode: TextureTileMode = TextureTileMode.RATIO:
	get: return texture_tile_mode
	set(value):
		if texture_tile_mode == value:
			return
		texture_tile_mode = value
		notify_property_list_changed()
		if _auto_rebuild and Engine.is_editor_hint():
			rebuild()
@export var texture_offset: float = 0.0:
	get: return texture_offset
	set(value):
		if texture_offset == value:
			return
		texture_offset = value
		if _auto_rebuild and Engine.is_editor_hint():
			rebuild()
@export var material_type: MaterialType = MaterialType.SOLID_UNLIT:
	get: return material_type
	set(value):
		if material_type == value:
			return
		material_type = value
		if material_type != MaterialType.CUSTOM:
			custom_material = null
		notify_property_list_changed()
		_refresh_material()
@export var custom_material: Material:
	get: return custom_material
	set(value):
		if custom_material == value:
			return
		custom_material = value
		_refresh_material()
@export var points: PackedVector3Array:
	get: return points
	set(value):
		points = value
		if _auto_rebuild and Engine.is_editor_hint():
			rebuild()
@export var curve_normals: PackedVector3Array:
	get: return curve_normals
	set(value):
		curve_normals = value
		if _auto_rebuild and Engine.is_editor_hint():
			rebuild()

var _vertices: PackedVector3Array
var _normals: PackedVector3Array
var _colors: PackedColorArray
var _uvs: PackedVector2Array
var _indices: PackedInt32Array
var _arrays: Array
var _auto_rebuild: bool = true


static var _built_in_materials: Dictionary
static var _built_in_billboard_materials: Dictionary


func _init() -> void:

	_arrays.resize(Mesh.ARRAY_MAX)
	_arrays[Mesh.ARRAY_VERTEX] = _vertices
	_arrays[Mesh.ARRAY_NORMAL] = _normals
	_arrays[Mesh.ARRAY_COLOR] = _colors
	_arrays[Mesh.ARRAY_TEX_UV] = _uvs
	_arrays[Mesh.ARRAY_INDEX] = _indices


func _validate_property(property: Dictionary) -> void:

	match property.name:
		"mesh":
			property.usage = PROPERTY_USAGE_NONE
		"curve_normals":
			if billboard_mode != BillboardMode.NONE:
				property.usage = PROPERTY_USAGE_NONE
		"custom_material":
			if material_type != MaterialType.CUSTOM:
				property.usage = PROPERTY_USAGE_NONE


func _ready() -> void:

	rebuild()


func _notification(what: int) -> void:

	match what:
		NOTIFICATION_TRANSFORM_CHANGED:
			_on_transform_changed()


func clear() -> void:

	points.clear()
	curve_normals.clear()
	_vertices.clear()
	_normals.clear()
	_colors.clear()
	_uvs.clear()
	_indices.clear()

	rebuild()


func rebuild() -> void:

	if not is_inside_tree() or not is_node_ready():
		return

	if not is_instance_valid(mesh):
		mesh = ArrayMesh.new()

	var am := mesh as ArrayMesh
	if am.get_surface_count() > 0:
		am.clear_surfaces()

	var point_count := points.size()
	if point_count < 2:
		return

	_vertices.resize(point_count * 3)
	_normals.resize(point_count * 3)
	_colors.resize(point_count * 3)
	_uvs.resize(point_count * 3)

	var new_index_count := (point_count - 1) * 12
	if _indices.size() != new_index_count:
		_indices.resize(new_index_count)
		for i in point_count - 1:
			var j := i * 12
			var k := i * 3
			_indices[j] = k
			_indices[j + 1] = k + 3
			_indices[j + 2] = k + 1
			_indices[j + 3] = k + 1
			_indices[j + 4] = k + 3
			_indices[j + 5] = k + 4
			_indices[j + 6] = k + 1
			_indices[j + 7] = k + 4
			_indices[j + 8] = k + 2
			_indices[j + 9] = k + 2
			_indices[j + 10] = k + 4
			_indices[j + 11] = k + 5

	var inv_global_tf: Transform3D
	if use_global_space:
		inv_global_tf = global_transform.inverse()

	var length: float = 0.0
	for i in range(1, point_count):
		length += points[i - 1].distance_to(points[i])

	var dist: float = 0.0

	for i in point_count:

		var j0 := i * 3
		var j1 := j0 + 1
		var j2 := j0 + 2

		var p := points[i]

		if i > 0:
			dist += points[i - 1].distance_to(p)

		var ratio := (dist / length) if (length > 0) else 0

		var u: float
		match texture_tile_mode:
			TextureTileMode.RATIO:
				u = ratio
			TextureTileMode.DISTANCE:
				u = dist
		u += texture_offset

		var half_width := width / 2
		if width_curve:
			half_width *= width_curve.sample(ratio)

		var tangent: Vector3
		if i == 0:
			tangent = (points[i + 1] - p).normalized()
		elif i == point_count - 1:
			tangent = (p - points[i - 1]).normalized()
		else:
			tangent = (p - points[i - 1]).lerp(points[i + 1] - p, 0.5).normalized()

		if use_global_space:
			p = inv_global_tf * p
			tangent = inv_global_tf.basis * tangent

		if billboard_mode == BillboardMode.VIEW:

			_vertices[j0] = p
			_vertices[j1] = p
			_vertices[j2] = p

			_normals[j0] = tangent
			_normals[j1] = tangent
			_normals[j2] = tangent

			_uvs[j0] = Vector2(u, -half_width)
			_uvs[j1] = Vector2(u, 0)
			_uvs[j2] = Vector2(u, half_width)

		else:

			var curve_normal: Vector3
			var normal: Vector3

			if billboard_mode == BillboardMode.Z:
				curve_normal = Vector3.BACK.cross(tangent).normalized()
				normal = Vector3.BACK
			else:
				if i < curve_normals.size():
					curve_normal = curve_normals[i]
					if use_global_space:
						curve_normal = inv_global_tf.basis * curve_normal
				else:
					curve_normal = Vector3.BACK
				normal = tangent.cross(curve_normal).normalized()

			_vertices[j0] = p + half_width * curve_normal
			_vertices[j1] = p
			_vertices[j2] = p - half_width * curve_normal

			_normals[j0] = normal
			_normals[j1] = normal
			_normals[j2] = normal

			_uvs[j0] = Vector2(u, 0)
			_uvs[j1] = Vector2(u, 0.5)
			_uvs[j2] = Vector2(u, 1)

		var c := color
		if gradient:
			c *= gradient.sample(ratio)
		_colors[j0] = c
		_colors[j1] = c
		_colors[j2] = c

	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, _arrays)

	_refresh_material()


func _refresh_material() -> void:

	var am: ArrayMesh = mesh
	if not am:
		return

	var mat: ShaderMaterial
	if material_type == MaterialType.CUSTOM:
		mat = custom_material
	else:
		var mat_dict := _built_in_billboard_materials if billboard_mode == BillboardMode.VIEW else _built_in_materials
		mat = mat_dict.get(material_type, null)
		if mat == null:
			var shader_path := "res://addons/lines_and_trails_3d/line_3d_"
			if billboard_mode == BillboardMode.VIEW:
				shader_path += "billboard_"
			shader_path += MaterialType.keys()[material_type].to_lower() + ".gdshader"
			mat = ShaderMaterial.new()
			mat.shader = load(shader_path)
			mat_dict[material_type] = mat

	if am.get_surface_count() > 0:
		if am.surface_get_material(0) != mat:
			am.surface_set_material(0, mat)


func _on_child_resource_changed() -> void:

	if _auto_rebuild and Engine.is_editor_hint():
		rebuild()


# VIRTUAL
func _on_transform_changed() -> void:

	if use_global_space:
		rebuild()
