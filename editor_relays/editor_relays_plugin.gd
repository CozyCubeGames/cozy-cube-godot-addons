@tool
class_name EditorRelaysPlugin
extends EditorPlugin


var _debugger_plugin := preload("res://addons/editor_relays/editor_relays_debugger_plugin.gd").new()

static var _instance: EditorRelaysPlugin


func _enter_tree() -> void:

	_instance = self
	add_custom_type("EditorRelay", "Node", preload("res://addons/editor_relays/editor_relay.gd"), preload("EditorRelay.svg"))
	add_debugger_plugin(_debugger_plugin)


func _exit_tree() -> void:

	_instance = null
	remove_custom_type("EditorRelay")
	remove_debugger_plugin(_debugger_plugin)
