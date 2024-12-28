@tool
class_name TransformCluster3D
extends Node


@export var nodes: Array[Node3D]:
	set(value):
		_disconnect_nodes()
		nodes = value
		_try_connect_nodes()
@export var enabled_in_editor: bool = true:
	set(value):
		enabled_in_editor = value
		if Engine.is_editor_hint():
			if value:
				_try_connect_nodes()
			else:
				_disconnect_nodes()
@export var enabled_at_runtime: bool = false:
	set(value):
		enabled_at_runtime = value
		if not Engine.is_editor_hint():
			if value:
				_try_connect_nodes()
			else:
				_disconnect_nodes()

var _applying_relations: bool
var _units: Array[TransformClusterUnit3D]
var _are_units_connected: bool


func _get_configuration_warnings() -> PackedStringArray:

	for node in nodes:
		if not is_instance_valid(node):
			return ["Invalid node(s) in cluster."]
	return []


func _ready() -> void:

	_try_connect_nodes()


func _notification(what: int) -> void:

	if what == NOTIFICATION_PREDELETE:
		if not is_queued_for_deletion():
			_disconnect_nodes()


func _disconnect_nodes() -> void:

	if not _are_units_connected:
		return

	for unit in _units:
		if is_instance_valid(unit):
			unit.free()
	_units.clear()
	_are_units_connected = false


func _try_connect_nodes() -> void:

	if _are_units_connected:
		return

	if not is_node_ready():
		return

	if Engine.is_editor_hint():
		if not enabled_in_editor:
			return
	else:
		if not enabled_at_runtime:
			return

	_units.clear()

	if nodes.size() <= 1:
		return

	for node in nodes:
		assert(is_instance_valid(node) and node.is_inside_tree())

	var first_node: Node3D = nodes[0]
	var inv_ref_tf := first_node.global_transform.orthonormalized().inverse()

	for i in nodes.size():
		var node := nodes[i]
		var unit := TransformClusterUnit3D.new()
		unit._cluster = self
		if i > 0:
			unit._rel_tf = inv_ref_tf * node.global_transform.orthonormalized()
			unit._inv_rel_tf = unit._rel_tf.inverse()
		node.add_child(unit)
		_units.append(unit)

	_are_units_connected = true


func _apply_relations(moved_unit: TransformClusterUnit3D) -> void:

	_applying_relations = true

	var first_node := nodes[0]
	assert(is_instance_valid(first_node) and first_node.is_inside_tree())
	var first_node_ortho_tf: Transform3D

	var moved_node := moved_unit.get_parent()
	if moved_node == first_node:
		first_node_ortho_tf = first_node.global_transform.orthonormalized()
	else:
		first_node_ortho_tf = moved_node.global_transform.orthonormalized() * moved_unit._inv_rel_tf
		var new_tf := first_node_ortho_tf.scaled_local(first_node.scale)
		if not new_tf.is_equal_approx(first_node.global_transform):
			first_node.global_transform = new_tf

	for i in range(1, nodes.size()):
		var unit := _units[i]
		if unit == moved_unit:
			continue
		var node := nodes[i]
		assert(is_instance_valid(node) and node.is_inside_tree())
		var new_tf := (first_node_ortho_tf * unit._rel_tf).scaled_local(node.scale)
		if not new_tf.is_equal_approx(node.global_transform):
			node.global_transform = new_tf

	_applying_relations = false
