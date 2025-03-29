@tool
class_name AreaLight3DGizmoPlugin
extends EditorNode3DGizmoPlugin


func _init() -> void:

	create_material("main", Color.WHITE, false, false, true)


func _get_gizmo_name() -> String:

	return "AreaLight3D"


func _has_gizmo(for_node_3d: Node3D) -> bool:

	return for_node_3d is AreaLight3D


func _redraw(gizmo: EditorNode3DGizmo) -> void:

	gizmo.clear()

	var light = gizmo.get_node_3d() as AreaLight3D
	var extents: Vector2 = light.area_size / 2
	var p1 := Vector3(-extents.x, extents.y, 0)
	var p2 := Vector3(extents.x, extents.y, 0)
	var p3 := Vector3(-extents.x, -extents.y, 0)
	var p4 := Vector3(extents.x, -extents.y, 0)

	gizmo.add_lines(
			PackedVector3Array([p1, p2, p1, p3, p2, p4, p3, p4]),
			get_material("main", gizmo),
			false,
			light.light_color * light.light_energy)
