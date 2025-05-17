@tool
class_name TilePath3D
extends Path3D


enum TileDirectionMode { FORWARD, FORWARD_OR_BACK, CARDINAL, FREE }
enum TileSelectionMode { RANDOM, RANDOM_NO_REPEATS, SEQUENTIAL }
enum GroundSeekDirectionMode { WORLD_DOWN, OBJECT_DOWN, CURVE_SAMPLE_DOWN }


@export var _tile_meshes: Array[Mesh]:
	get: return _tile_meshes
	set(value):
		if _tile_meshes == value:
			return
		if Engine.is_editor_hint():
			for m in _tile_meshes:
				if m:
					m.changed.disconnect(rebuild)
		_tile_meshes = value
		if Engine.is_editor_hint():
			for m in _tile_meshes:
				if m:
					m.changed.connect(rebuild, CONNECT_REFERENCE_COUNTED)
		rebuild()
@export var _tile_material: Material:
	get: return _tile_material
	set(value):
		if _tile_material == value:
			return
		_tile_material = value
		rebuild()
@export var _tile_spacing: float = 0.15:
	get: return _tile_spacing
	set(value):
		if _tile_spacing == value:
			return
		_tile_spacing = value
		rebuild()
@export var _tile_lateral_scale_curve: Curve:
	get: return _tile_lateral_scale_curve
	set(value):
		if _tile_lateral_scale_curve == value:
			return
		if Engine.is_editor_hint():
			if _tile_lateral_scale_curve:
				_tile_lateral_scale_curve.changed.disconnect(rebuild)
		_tile_lateral_scale_curve = value
		if Engine.is_editor_hint():
			if _tile_lateral_scale_curve:
				_tile_lateral_scale_curve.changed.connect(rebuild, CONNECT_REFERENCE_COUNTED)
		rebuild()
@export var _tile_vertical_scale_curve: Curve:
	get: return _tile_vertical_scale_curve
	set(value):
		if _tile_vertical_scale_curve == value:
			return
		if Engine.is_editor_hint():
			if _tile_vertical_scale_curve:
				_tile_vertical_scale_curve.changed.disconnect(rebuild)
		_tile_vertical_scale_curve = value
		if Engine.is_editor_hint():
			if _tile_vertical_scale_curve:
				_tile_vertical_scale_curve.changed.connect(rebuild, CONNECT_REFERENCE_COUNTED)
		rebuild()
@export var _tile_mmis: Array[MultiMeshInstance3D]

@export_group("Randomness")
@export var _tile_selection_mode: TileSelectionMode = TileSelectionMode.RANDOM_NO_REPEATS:
	get: return _tile_selection_mode
	set(value):
		if _tile_selection_mode == value:
			return
		_tile_selection_mode = value
		rebuild()
@export var _tile_direction_mode: TileDirectionMode = TileDirectionMode.FORWARD:
	get: return _tile_direction_mode
	set(value):
		if _tile_direction_mode == value:
			return
		_tile_direction_mode = value
		rebuild()
@export_range(0.0, 90.0, 0.5) var _tile_angle_jitter: float = 0.0:
	get: return _tile_angle_jitter
	set(value):
		if _tile_angle_jitter == value:
			return
		_tile_angle_jitter = value
		rebuild()
@export_range(0.0, 1.0, 0.01) var _tile_lateral_scale_jitter: float = 0.0:
	get: return _tile_lateral_scale_jitter
	set(value):
		if _tile_lateral_scale_jitter == value:
			return
		_tile_lateral_scale_jitter = value
		rebuild()
@export_range(0.0, 1.0, 0.01) var _tile_vertical_scale_jitter: float = 0.0:
	get: return _tile_vertical_scale_jitter
	set(value):
		if _tile_vertical_scale_jitter == value:
			return
		_tile_vertical_scale_jitter = value
		rebuild()
@export var _rand_seed: int = 0:
	get: return _rand_seed
	set(value):
		if _rand_seed == value:
			return
		_rand_seed = value
		rebuild()

@export_group("Grounding")
@export var _grounded: bool = true:
	get: return _grounded
	set(value):
		if _grounded == value:
			return
		_grounded = value
		notify_property_list_changed()
		rebuild()
@export var _ground_nodes: Array[MeshInstance3D]:
	get: return _ground_nodes
	set(value):
		if _ground_nodes == value:
			return
		_ground_nodes = value
		rebuild()
@export var _height_from_ground: float = 0.0:
	get: return _height_from_ground
	set(value):
		if _height_from_ground == value:
			return
		_height_from_ground = value
		rebuild()
@export var _height_from_ground_curve: Curve:
	get: return _height_from_ground_curve
	set(value):
		if _height_from_ground_curve == value:
			return
		if Engine.is_editor_hint():
			if _height_from_ground_curve:
				_height_from_ground_curve.changed.disconnect(rebuild)
		_height_from_ground_curve = value
		if Engine.is_editor_hint():
			if _height_from_ground_curve:
				_height_from_ground_curve.changed.connect(rebuild, CONNECT_REFERENCE_COUNTED)
		rebuild()
@export_range(0.0, 1.0, 0.01) var _ground_normal_adherence: float = 1.0:
	get: return _ground_normal_adherence
	set(value):
		if _ground_normal_adherence == value:
			return
		_ground_normal_adherence = value
		rebuild()
@export_range(0.0, 1.0, 0.01) var _ground_normal_relaxation: float = 0.5:
	get: return _ground_normal_relaxation
	set(value):
		if _ground_normal_relaxation == value:
			return
		_ground_normal_relaxation = value
		rebuild()
@export var _ground_seek_direction_mode: GroundSeekDirectionMode = GroundSeekDirectionMode.WORLD_DOWN:
	get: return _ground_seek_direction_mode
	set(value):
		if _ground_seek_direction_mode == value:
			return
		_ground_seek_direction_mode = value
		rebuild()


func _ready() -> void:

	if Engine.is_editor_hint():
		curve_changed.connect(rebuild)
		set_notify_transform(true)


func _validate_property(property: Dictionary) -> void:

	if not _grounded:
		if property.name.contains("ground") and property.name != "_grounded":
			property.usage = PROPERTY_USAGE_STORAGE

	if property.name == "_tile_mmis":
		property.usage |= PROPERTY_USAGE_READ_ONLY


func _notification(what: int) -> void:

	if what == NOTIFICATION_TRANSFORM_CHANGED:
		rebuild()


func rebuild() -> void:

	if owner != EditorInterface.get_edited_scene_root():
		return
	if not Engine.is_editor_hint() or not is_node_ready():
		return

	# Remove any invalid ground nodes.
	for i in range(_ground_nodes.size() - 1, -1, -1):
		if not is_instance_valid(_ground_nodes[i]) or not _ground_nodes[i].is_inside_tree():
			_ground_nodes.pop_back()

	# Ensure MultiMeshInstance parity.
	while _tile_mmis.size() > _tile_meshes.size():
		var mmi := _tile_mmis.pop_back() as MultiMeshInstance3D
		if is_instance_valid(mmi):
			mmi.free()
	_tile_mmis.resize(_tile_meshes.size())

	# Ensure MultiMesh parity.
	for i in _tile_mmis.size():
		var mmi := _tile_mmis[i]
		if not is_instance_valid(mmi) or not mmi.is_inside_tree():
			mmi = MultiMeshInstance3D.new()
			mmi.name = "tile_mmi_" + str(i)
			_tile_mmis[i] = mmi
			add_child(mmi)
			mmi.owner = owner
		mmi.multimesh = MultiMesh.new()
		mmi.multimesh.instance_count = 0
		mmi.multimesh.transform_format = MultiMesh.TRANSFORM_3D
		var mesh := _tile_meshes[i]
		mmi.multimesh.mesh = mesh
		mmi.transform = Transform3D.IDENTITY
		mmi.material_override = _tile_material

	# TODO: Wipe collisions.

	if _tile_meshes.is_empty():
		return

	var ground_tfs: Array[Transform3D]
	var ground_inv_tfs: Array[Transform3D]
	var ground_tris: Array[PackedVector3Array]
	var ground_normals: Array[PackedVector3Array]
	if _grounded and not _ground_nodes.is_empty():
		for i in range(_ground_nodes.size() - 1, -1, -1):
			var ground_mi := _ground_nodes.back()
			if not is_instance_valid(ground_mi) or not is_instance_valid(ground_mi.mesh):
				_ground_nodes.pop_back()
		var st: SurfaceTool
		for ground_mi in _ground_nodes:
			ground_tfs.append(ground_mi.global_transform)
			ground_inv_tfs.append(ground_mi.global_transform.affine_inverse())
			var tris: PackedVector3Array
			if ground_mi.mesh is PrimitiveMesh:
				if not st:
					st = SurfaceTool.new()
				st.clear()
				st.append_from(ground_mi.mesh, 0, Transform3D.IDENTITY)
				tris = st.commit().get_faces()
			else:
				tris = ground_mi.mesh.get_faces()
			ground_tris.append(tris)
			var normals: PackedVector3Array
			normals.resize(floori(tris.size() / 3.0))
			for j in normals.size():
				var a := tris[j * 3]
				var b := tris[j * 3 + 1]
				var c := tris[j * 3 + 2]
				normals[j] = (c - a).cross(b - a).normalized()
			ground_normals.append(normals)
	var tile_tfs: Array[Array]
	for i in _tile_mmis.size():
		tile_tfs.append(Array())

	var length: float = curve.get_baked_length()
	var dist: float = 0.0
	var iterations: int = 0
	var mesh_idx: int = -1

	var rand := RandomNumberGenerator.new()
	rand.seed = _rand_seed

	var root_half := sqrt(0.5)
	var tf := global_transform
	var inv_tf := tf.affine_inverse()
	var sequence: Array[Vector2i]

	while dist < length and iterations < 9999:

		iterations += 1

		var yaw: float
		match _tile_direction_mode:
			TileDirectionMode.FORWARD_OR_BACK:
				yaw = (rand.randi() % 2) * 180
			TileDirectionMode.CARDINAL:
				yaw = (rand.randi() % 4) * 90
			TileDirectionMode.FREE:
				yaw = rand.randf() * 360
		yaw += rand.randf_range(-0.5, 0.5) * _tile_angle_jitter

		var turn_basis := Basis(Vector3.UP, deg_to_rad(yaw))

		var t := dist / length
		var lateral_scale := _tile_lateral_scale_curve.sample(t) if _tile_lateral_scale_curve else 1.0
		var vertical_scale := _tile_vertical_scale_curve.sample(t) if _tile_vertical_scale_curve else 1.0
		lateral_scale *= 1 + rand.randf_range(-0.5, 0.5) * _tile_lateral_scale_jitter
		vertical_scale *= 1 + rand.randf_range(-0.5, 0.5) * _tile_vertical_scale_jitter
		lateral_scale = maxf(0.1, lateral_scale)

		mesh_idx = _select_tile_mesh(rand, mesh_idx)
		var mesh := _tile_meshes[mesh_idx]

		var tile_length: float

		if is_instance_valid(mesh):
			var aabb := mesh.get_aabb()
			if absf(turn_basis.z.z) >= root_half:
				tile_length = maxf(absf(aabb.position.z), absf(aabb.end.z)) * 2
			else:
				tile_length = maxf(absf(aabb.position.x), absf(aabb.end.x)) * 2
		else:
			tile_length = 1.0

		tile_length *= lateral_scale

		var center_dist := dist + tile_length / 2
		var sampled_tf := curve.sample_baked_with_rotation(center_dist, true, true)
		var p := sampled_tf.origin
		if center_dist > length:
			p -= sampled_tf.basis.z * (center_dist - length)
		var b := sampled_tf.basis
		match _ground_seek_direction_mode:
			GroundSeekDirectionMode.WORLD_DOWN:
				b = Basis(Quaternion(b.y, inv_tf.basis.y.normalized())) * b
			GroundSeekDirectionMode.OBJECT_DOWN:
				b = Basis(Quaternion(b.y, Vector3.UP)) * b
		b *= turn_basis

		if _grounded and not _ground_nodes.is_empty():

			var seek_dir: Vector3
			match _ground_seek_direction_mode:
				GroundSeekDirectionMode.WORLD_DOWN:
					seek_dir = Vector3.DOWN
				GroundSeekDirectionMode.OBJECT_DOWN:
					seek_dir = -tf.basis.y.normalized()
				GroundSeekDirectionMode.CURVE_SAMPLE_DOWN:
					seek_dir = (tf.basis * -b.y).normalized()

			var intersect = _get_ground_intersect(
					tf * p - seek_dir * 2,
					seek_dir,
					ground_tfs,
					ground_inv_tfs,
					ground_tris,
					ground_normals)
			if intersect == null:
				dist += 0.2
				continue

			p = inv_tf * intersect[0]
			var n: Vector3 = (inv_tf.basis * intersect[1]).normalized()
			var h := _height_from_ground
			if _height_from_ground_curve:
				h += _height_from_ground_curve.sample(t)
			p += n * h
			if _ground_normal_adherence > 0:
				var b_ground_adhering := Basis(Quaternion(b.y, n)) * b
				if _ground_normal_adherence < 1:
					b = b.slerp(b_ground_adhering, _ground_normal_adherence)
				else:
					b = b_ground_adhering

		b *= Basis.from_scale(Vector3(lateral_scale, vertical_scale, lateral_scale))

		tile_tfs[mesh_idx].append(Transform3D(b, p))
		sequence.append(Vector2i(mesh_idx, tile_tfs[mesh_idx].size() - 1))

		dist += tile_length + _tile_spacing * lateral_scale

	if _ground_normal_relaxation > 0 and sequence.size() > 1:

		var relaxed_normals: Array[Vector3]
		relaxed_normals.resize(sequence.size())

		for i in relaxed_normals.size():
			var s0 := sequence[(i - 1) if (i > 0) else i]
			var s1 := sequence[i]
			var s2 := sequence[(i + 1) if (i < relaxed_normals.size() - 1) else i]
			var tf0: Transform3D = tile_tfs[s0[0]][s0[1]]
			var tf1: Transform3D = tile_tfs[s1[0]][s1[1]]
			var tf2: Transform3D = tile_tfs[s2[0]][s2[1]]
			var forward := tf1.origin.lerp(tf2.origin, 0.5) - tf1.origin.lerp(tf0.origin, 0.5)
			var n := tf1.basis.y
			var right := forward.cross(n)
			relaxed_normals[i] = right.cross(forward).normalized()

		for i in relaxed_normals.size():
			var s := sequence[i]
			var tile_tf: Transform3D = tile_tfs[s[0]][s[1]]
			var n := tile_tf.basis.y.normalized()
			var q_relax = Quaternion(n, relaxed_normals[i])
			q_relax = Quaternion.IDENTITY.slerp(q_relax, _ground_normal_relaxation)
			tile_tf.basis = Basis(q_relax) * tile_tf.basis
			tile_tfs[s[0]][s[1]] = tile_tf

	for i in tile_tfs.size():
		var tfs := tile_tfs[i]
		var mmi := _tile_mmis[i]
		var mm := mmi.multimesh
		if is_instance_valid(mmi.multimesh.mesh):
			mm.instance_count = tfs.size()
			for j in tfs.size():
				mm.set_instance_transform(j, tfs[j])


func _select_tile_mesh(rand: RandomNumberGenerator, last_idx: int) -> int:

	match _tile_selection_mode:
		TileSelectionMode.RANDOM:
			return rand.randi_range(0, _tile_meshes.size() - 1)
		TileSelectionMode.RANDOM_NO_REPEATS:
			return rand.randi_range(last_idx + 1, last_idx + _tile_meshes.size() - 1) % _tile_meshes.size()
		TileSelectionMode.SEQUENTIAL:
			return (last_idx + 1) % _tile_meshes.size()
	return -1


func _get_ground_intersect(
		from: Vector3,
		dir: Vector3,
		ground_tfs: Array[Transform3D],
		ground_inv_tfs: Array[Transform3D],
		ground_tris: Array[PackedVector3Array],
		ground_normals: Array[PackedVector3Array]) -> Variant:

	var nearest_dist: float = 5.0
	var nearest_intersect: Variant

	for i in ground_inv_tfs.size():
		var tf: Transform3D = ground_tfs[i]
		var s := tf.basis.get_scale()
		var normal_basis := tf.basis
		normal_basis.x /= s.x * s.x
		normal_basis.y /= s.y * s.y
		normal_basis.z /= s.z * s.z
		var inv_tf: Transform3D = ground_inv_tfs[i]
		var tris: PackedVector3Array = ground_tris[i]
		var normals: PackedVector3Array = ground_normals[i]
		var local_from := inv_tf * from
		var local_dir := (inv_tf.basis * dir).normalized()

		for j in floori(tris.size() / 3.0):

			var start_idx := j * 3
			var a := tris[start_idx]
			var b := tris[start_idx + 1]
			var c := tris[start_idx + 2]

			var intersect = Geometry3D.ray_intersects_triangle(local_from, local_dir, a, b, c)
			if intersect == null:
				continue

			var world_intersect: Vector3 = tf * intersect
			var d: float = (world_intersect - from).dot(dir)
			if d > 0 and d < nearest_dist:
				nearest_dist = d
				nearest_intersect = [world_intersect, normal_basis * normals[j]]

	return nearest_intersect
