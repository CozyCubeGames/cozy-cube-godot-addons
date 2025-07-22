@tool
class_name SyncedCollisionShape3D
extends CollisionShape3D


@export var source: MeshInstance3D:
	get: return source
	set(value):
		if value == source:
			return
		if _cached_source_mesh:
			_cached_source_mesh.changed.disconnect(_on_source_mesh_changed)
		_cached_source_mesh = null
		_cached_source_tf = Transform3D.IDENTITY
		source = value
		if source:
			_cached_source_mesh = source.mesh
			if _cached_source_mesh:
				_cached_source_mesh.changed.connect(_on_source_mesh_changed)
			set_process(_should_auto_sync() and source and source.mesh)
		else:
			shape = null
			set_process(false)
		if _should_auto_sync():
			sync()
		notify_property_list_changed()
@export var force_polygon_shape: bool = false:
	get: return force_polygon_shape
	set(value):
		if value == force_polygon_shape:
			return
		force_polygon_shape = value
		if _should_auto_sync():
			sync()
		notify_property_list_changed()
@export var convex: bool = true:
	get: return convex
	set(value):
		if value == convex:
			return
		convex = value
		if _should_auto_sync():
			sync()
@export var surface_idx: int = -1:
	get: return surface_idx
	set(value):
		if value == surface_idx:
			return
		surface_idx = maxi(-1, value)
		if _should_auto_sync():
			sync()
@export var editor_auto_sync: bool = true:
	get: return editor_auto_sync
	set(value):
		if value == editor_auto_sync:
			return
		editor_auto_sync = value
		set_process(_should_auto_sync() and source and source.mesh)
		notify_property_list_changed()
@export var runtime_auto_sync: bool = false:
	get: return runtime_auto_sync
	set(value):
		if value == runtime_auto_sync:
			return
		runtime_auto_sync = value
		set_process(_should_auto_sync() and source and source.mesh)
@export_tool_button("Sync") var sync_action := sync

var _cached_source_mesh: Mesh
var _cached_source_tf: Transform3D


func _ready() -> void:

	if _should_auto_sync():
		if source and source.is_visible_in_tree():
			_cached_source_tf = source.global_transform

	set_process(_should_auto_sync() and source and source.mesh)


func _validate_property(property: Dictionary) -> void:

	match property.name:
		"force_polygon_shape":
			if is_instance_valid(source) and is_instance_valid(source.mesh):
				if not (source.mesh is SphereMesh or\
						source.mesh is BoxMesh or\
						source.mesh is CapsuleMesh or\
						source.mesh is CylinderMesh):
					property.usage = PROPERTY_USAGE_STORAGE
			else:
				property.usage = PROPERTY_USAGE_STORAGE
		"convex", "surface_idx":
			if is_instance_valid(source) and is_instance_valid(source.mesh):
				if source.mesh is SphereMesh or\
						source.mesh is BoxMesh or\
						source.mesh is CapsuleMesh or\
						source.mesh is CylinderMesh:
					property.usage = PROPERTY_USAGE_STORAGE
			else:
				property.usage = PROPERTY_USAGE_STORAGE
		"sync_action":
			if editor_auto_sync:
				property.usage = PROPERTY_USAGE_NONE


func _process(_delta: float) -> void:

	if is_instance_valid(source):

		var needs_sync: bool

		if source.mesh != _cached_source_mesh:
			if is_instance_valid(_cached_source_mesh):
				_cached_source_mesh.changed.disconnect(_on_source_mesh_changed)
			_cached_source_mesh = source.mesh
			needs_sync = true
			if is_instance_valid(_cached_source_mesh):
				_cached_source_mesh.changed.connect(_on_source_mesh_changed)

		if not _cached_source_tf.is_equal_approx(source.global_transform):
			needs_sync = true

		if needs_sync:
			sync()

	else:

		set_process(false)


func sync() -> void:

	if not is_node_ready():
		return
	if not is_instance_valid(source) or not is_instance_valid(source.mesh):
		shape = null
		return
	if not is_inside_tree() or not source.is_inside_tree():
		return

	_cached_source_tf = source.global_transform
	var target_tf := _cached_source_tf.orthonormalized()
	global_transform = target_tf

	var had_shape := is_instance_valid(shape)
	var old_custom_solver_bias: float
	var old_margin: float
	if had_shape:
		old_custom_solver_bias = shape.custom_solver_bias
		old_margin = shape.margin

	var use_poly_shape := force_polygon_shape

	if not use_poly_shape:
		if source.mesh is SphereMesh:
			shape = SphereShape3D.new()
			var source_scale := _cached_source_tf.basis.get_scale().abs()
			shape.radius = maxf(
					source.mesh.radius * maxf(source_scale.x, source_scale.z),
					source.mesh.height * (1.0 if source.mesh.is_hemisphere else 0.5) * source_scale.y)
		elif source.mesh is BoxMesh:
			shape = BoxShape3D.new()
			var source_scale := _cached_source_tf.basis.get_scale().abs()
			shape.size = source.mesh.size * source_scale
		elif source.mesh is CapsuleMesh:
			shape = CapsuleShape3D.new()
			var source_scale := _cached_source_tf.basis.get_scale().abs()
			shape.radius = source.mesh.radius * maxf(source_scale.x, source_scale.z)
			shape.height = source.mesh.height * source_scale.y
		elif source.mesh is CylinderMesh:
			shape = CylinderShape3D.new()
			var source_scale := _cached_source_tf.basis.get_scale().abs()
			shape.radius = maxf(source.mesh.top_radius, source.mesh.bottom_radius) * maxf(source_scale.x, source_scale.z)
			shape.height = source.mesh.height * source_scale.y
		else:
			use_poly_shape = true

	if use_poly_shape:
		var distortion := target_tf.basis.inverse() * _cached_source_tf.basis
		var mesh := source.mesh
		if convex:
			shape = ConvexPolygonShape3D.new()
			var points: PackedVector3Array
			for i in mesh.get_surface_count():
				if surface_idx == -1 or surface_idx == i:
					var arrays := mesh.surface_get_arrays(i)
					points.append_array(arrays[Mesh.ARRAY_VERTEX])
			for i in points.size():
				points[i] = distortion * points[i]
			shape.points = points
		else:
			shape = ConcavePolygonShape3D.new()
			var faces: PackedVector3Array
			for i in mesh.get_surface_count():
				if surface_idx == -1 or surface_idx == i:
					var arrays := mesh.surface_get_arrays(i)
					var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
					for j in verts.size():
						verts[j] = distortion * verts[j]
					var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
					var surf_faces: PackedVector3Array
					surf_faces.resize(indices.size())
					for j in indices:
						surf_faces[j] = verts[indices[j]]
					faces.append_array(surf_faces)
			shape.set_faces(faces)

	if had_shape:
		shape.custom_solver_bias = old_custom_solver_bias
		shape.margin = old_margin

func _should_auto_sync() -> bool:

	if Engine.is_editor_hint():
		if not editor_auto_sync:
			return false
		if EditorInterface.get_edited_scene_root() != owner:
			return false
	else:
		if not runtime_auto_sync:
			return false
	if not is_node_ready():
		return false
	return true


func _on_source_mesh_changed() -> void:

	if _should_auto_sync():
		sync()
