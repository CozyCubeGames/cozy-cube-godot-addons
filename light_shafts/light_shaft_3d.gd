@tool
class_name LightShaft3D
extends MeshInstance3D


const LocalTransformListener = preload("uid://c1u7eyhigk821")

@export var outline: Path3D:
	get: return outline
	set(value):
		if value == outline:
			return
		if is_instance_valid(outline):
			outline.disconnect("local_transform_changed", _rebuild)
			if is_instance_valid(outline.curve):
				outline.curve.changed.disconnect(_rebuild)
		outline = value
		if is_node_ready():
			_rebuild()
		if is_instance_valid(outline):
			outline.connect("local_transform_changed", _rebuild)
			if is_instance_valid(outline.curve):
				outline.curve.changed.connect(_rebuild)
@export var origin: Marker3D:
	get: return origin
	set(value):
		if value == origin:
			return
		if is_instance_valid(origin):
			origin.disconnect("local_transform_changed", _rebuild)
		origin = value
		if is_node_ready():
			_rebuild()
		if is_instance_valid(origin):
			origin.connect("local_transform_changed", _rebuild)
@export var length: float = 2.0:
	get: return length
	set(value):
		if value == length:
			return
		length = value
		if is_node_ready():
			_rebuild()
@export var spread: bool = true:
	get: return spread
	set(value):
		if value == spread:
			return
		spread = value
		if is_node_ready():
			_rebuild()
@export var color: Color = Color(1, 1, 0.5, 0.5):
	get: return color
	set(value):
		if value == color:
			return
		color = value
		if is_node_ready():
			_rebuild()
@export var uv_tile_count: int = 1.0:
	get: return uv_tile_count
	set(value):
		if value == uv_tile_count:
			return
		uv_tile_count = value
		if is_node_ready():
			_rebuild()


func _ready() -> void:

	if not is_instance_valid(outline) or not is_instance_valid(origin) or not is_instance_valid(mesh):
		_rebuild()


func _rebuild() -> void:

	if not is_node_ready():
		return
	if Engine.is_editor_hint() and EditorInterface.get_edited_scene_root() != owner:
		return

	if not is_instance_valid(outline):
		var new_outline = Path3D.new()
		new_outline.set_script(LocalTransformListener)
		new_outline.name = "outline"
		new_outline.curve = Curve3D.new()
		new_outline.curve.clear_points()
		new_outline.curve.add_point(Vector3(-1, 0, -1))
		new_outline.curve.add_point(Vector3(1, 0, -1))
		new_outline.curve.add_point(Vector3(1, 0, 1))
		new_outline.curve.add_point(Vector3(-1, 0, 1))
		new_outline.curve.closed = true
		add_child(new_outline)
		new_outline.owner = owner
		outline = new_outline

	if not is_instance_valid(origin):
		var new_origin = Marker3D.new()
		new_origin.set_script(LocalTransformListener)
		new_origin.name = "origin"
		new_origin.transform = Transform3D(Basis(Vector3.RIGHT, deg_to_rad(-90)), Vector3(0, 1, 0))
		add_child(new_origin)
		new_origin.owner = owner
		origin = new_origin

	if not is_instance_valid(mesh):
		mesh = ArrayMesh.new()

	var verts: PackedVector3Array
	var normals: PackedVector3Array
	var colors: PackedColorArray
	var uvs: PackedVector2Array
	var indices: PackedInt32Array

	var origin_pos := to_local(origin.global_position)
	var dir_from_origin := -origin_pos.normalized()
	var outline_length := outline.curve.get_baked_length()

	for i in outline.curve.point_count + 1:
		var p := to_local(outline.to_global(outline.curve.get_point_position(i % outline.curve.point_count)))
		verts.append(p)
		var dir := (p - origin_pos).normalized() if spread else dir_from_origin
		verts.append(p + dir * length)
		var n := p.normalized()
		normals.append(n)
		normals.append(n)

	var prev_p := verts[0]
	var dist: float = 0.0
	for i in verts.size() / 2:
		var p := verts[i * 2]
		dist += prev_p.distance_to(p)
		var u := dist / outline_length * uv_tile_count
		uvs.append(Vector2(u, 1))
		uvs.append(Vector2(u, 0))
		prev_p = p

	for i in outline.curve.point_count:
		var b := i * 2
		indices.append(b + 0)
		indices.append(b + 1)
		indices.append(b + 2)
		indices.append(b + 2)
		indices.append(b + 1)
		indices.append(b + 3)

	colors.resize(verts.size())
	colors.fill(color)

	var arrays: Array
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices

	var old_mat: Material
	if mesh.get_surface_count() > 0:
		old_mat = mesh.surface_get_material(0)
		mesh.clear_surfaces()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	if old_mat:
		mesh.surface_set_material(0, old_mat)
	else:
		mesh.surface_set_material(0, load("uid://dqgh45ow7ygkh"))
