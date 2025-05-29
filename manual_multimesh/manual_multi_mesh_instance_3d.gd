@tool
class_name ManualMultiMeshInstance3D
extends MultiMeshInstance3D


@export_tool_button("Sync from Children") var sync_action := sync_from_children


func _ready() -> void:

	if is_instance_valid(multimesh):
		if multimesh.transform_format != MultiMesh.TRANSFORM_3D:
			var n := multimesh.instance_count
			multimesh.instance_count = 0
			multimesh.transform_format = MultiMesh.TRANSFORM_3D
			multimesh.instance_count = n

	if Engine.is_editor_hint():
		child_order_changed.connect(sync_from_children)


func _get_configuration_warnings() -> PackedStringArray:

	for child in get_children():
		if child is not ManualMultiMeshChild3D:
			return ["All children of ManualMultiMeshInstance3D must be ManualMultiMeshChild3D."]
	return []


func sync_from_children() -> void:

	if not is_instance_valid(multimesh):
		return
	if not is_instance_valid(multimesh.mesh):
		return

	var children := get_children()

	if multimesh.transform_format != MultiMesh.TRANSFORM_3D:
		multimesh.instance_count = 0
		multimesh.transform_format = MultiMesh.TRANSFORM_3D

	multimesh.instance_count = children.size()

	var i: int = 0
	for child in children:
		if child is not ManualMultiMeshChild3D:
			continue
		if not child.visible:
			continue
		multimesh.set_instance_transform(i, child.transform)
		if multimesh.use_colors:
			multimesh.set_instance_color(i, child.color)
		if multimesh.use_custom_data:
			multimesh.set_instance_custom_data(i, child.custom_data)
		i += 1
	multimesh.visible_instance_count = i
