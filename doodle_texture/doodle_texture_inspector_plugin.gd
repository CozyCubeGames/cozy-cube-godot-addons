@tool
class_name DoodleTextureInspectorPlugin
extends EditorInspectorPlugin


const DOODLE_TEXTURE_PAINTER_SCN: PackedScene = preload("res://addons/doodle_texture/doodle_texture_painter.tscn")

var _tex: DoodleTexture


func _can_handle(object: Object) -> bool:

	return object is DoodleTexture


func _parse_begin(object: Object) -> void:

	_tex = object


func _parse_category(object: Object, category: String) -> void:

	if category != "doodle_texture.gd":
		return

	var painter: DoodleTexturePainter = DOODLE_TEXTURE_PAINTER_SCN.instantiate()
	painter.texture = _tex
	add_custom_control(painter)
