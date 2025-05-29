@tool
class_name ManualMultiMeshChild3D
extends Node3D


@export var color: Color = Color.WHITE:
	get: return color
	set(value):
		if color == value:
			return
		color = value
		if is_node_ready():
			_notify_parent()
@export var custom_data: Color = Color.BLACK:
	get: return custom_data
	set(value):
		if custom_data == value:
			return
		custom_data = value
		if is_node_ready():
			_notify_parent()


func _ready() -> void:

	if Engine.is_editor_hint():
		set_notify_local_transform(true)


func _get_configuration_warnings() -> PackedStringArray:

	if get_parent() is not ManualMultiMeshInstance3D:
		return ["ManualMultiMeshChild3D must be a direct child of a ManualMultiMeshInstance3D."]
	return []


func _notification(what: int) -> void:

	match what:
		NOTIFICATION_LOCAL_TRANSFORM_CHANGED, NOTIFICATION_VISIBILITY_CHANGED:
			if is_node_ready():
				_notify_parent()


func _notify_parent() -> void:

	var mmi := get_parent() as ManualMultiMeshInstance3D
	if is_instance_valid(mmi):
		mmi.sync_from_children()
