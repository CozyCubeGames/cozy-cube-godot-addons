@tool
extends Node3D


signal local_transform_changed()


func _ready() -> void:

	set_notify_local_transform(true)


func _notification(what: int) -> void:

	if what == NOTIFICATION_LOCAL_TRANSFORM_CHANGED:
		local_transform_changed.emit()
