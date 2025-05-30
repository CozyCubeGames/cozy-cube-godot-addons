@tool
class_name ManualMultiMeshChild3D
extends Node3D


@export var color: Color = Color.WHITE:
	get: return color
	set(value):
		if color == value:
			return
		color = value
		_notify_parent()
@export var custom_data: Color = Color.BLACK:
	get: return custom_data
	set(value):
		if custom_data == value:
			return
		custom_data = value
		_notify_parent()


func _ready() -> void:

	if Engine.is_editor_hint() and EditorInterface.get_edited_scene_root() == owner:
		set_notify_local_transform(true)


func _get_configuration_warnings() -> PackedStringArray:

	if get_parent() is not ManualMultiMeshInstance3D:
		return ["ManualMultiMeshChild3D must be a direct child of a ManualMultiMeshInstance3D."]
	return []


func _notification(what: int) -> void:

	match what:
		NOTIFICATION_LOCAL_TRANSFORM_CHANGED, NOTIFICATION_VISIBILITY_CHANGED:
			_notify_parent()


func _notify_parent() -> void:

	return

	if not Engine.is_editor_hint():
		return
	if EditorInterface.get_edited_scene_root() != owner:
		return
	if not is_node_ready():
		return

	var mmi := get_parent() as ManualMultiMeshInstance3D
	if not is_instance_valid(mmi):
		return

	mmi._sync_from_children()
