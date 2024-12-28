@tool
class_name TransformClusterUnit3D
extends Node3D


var _cluster: TransformCluster3D
var _rel_tf: Transform3D
var _inv_rel_tf: Transform3D


func _enter_tree() -> void:

	set_notify_transform(true)


func _notification(what: int) -> void:

	if what == NOTIFICATION_TRANSFORM_CHANGED:
		if is_instance_valid(_cluster) and not _cluster._applying_relations:
			_cluster._apply_relations(self)
