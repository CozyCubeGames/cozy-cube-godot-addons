@tool
class_name DoodleTexturePainter
extends Control


@onready var texture_rect: TextureRect = $texture_rect

var texture: DoodleTexture
var _drawing: bool
var _background: bool
var _prev_tex_p: Vector2
var _data_before_drawing: PackedByteArray
var _size_before_drawing: Vector2i
var _last_known_size: Vector2i


func _enter_tree() -> void:

	for sibling in get_parent().get_children():
		if sibling.get_class() == "TexturePreview":
			sibling.visible = false


func _ready() -> void:

	texture_rect.texture = texture
	_last_known_size = texture.size


func _gui_input(event: InputEvent) -> void:

	if event is InputEventMouseButton:

		if event.is_pressed():
			match event.button_index:
				MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT:
					if not _drawing:
						var tex_p := _control_to_texture_point(event.position)
						_size_before_drawing = texture.size
						_data_before_drawing = texture.get_image().get_data()
						_drawing = true
						_background = (event.button_index == MOUSE_BUTTON_RIGHT)
						texture.draw_line(tex_p, tex_p, _background)
						_prev_tex_p = tex_p
						get_viewport().set_input_as_handled()
		elif event.is_released():
			match event.button_index:
				MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT:
					if _drawing:
						_drawing = false
						var size := texture.size
						var data := texture.get_image().get_data()
						var ur := DoodleTexturePlugin.instance.get_undo_redo()
						ur.create_action("Draw stroke")
						ur.add_do_method(texture, "set_data", size.x, size.y, data)
						ur.add_undo_method(texture, "set_data", _size_before_drawing.x, _size_before_drawing.y, _data_before_drawing)
						ur.commit_action(false)
						get_viewport().set_input_as_handled()

	elif event is InputEventMouseMotion:

		if not _drawing:
			return

		var tex_p := _control_to_texture_point(event.position)
		texture.draw_line(_prev_tex_p, tex_p, _background)
		_prev_tex_p = tex_p
		get_viewport().set_input_as_handled()


func _is_within_region(p: Vector2) -> bool:

	return p.x >= 0 and p.x <= texture.size.x and p.y >= 0 and p.y <= texture.size.y


func _control_to_texture_point(p: Vector2) -> Vector2:

	var rect_size := texture_rect.size
	var tex_size := texture.size
	var rect_aspect := rect_size.x / rect_size.y
	var tex_aspect := float(tex_size.x) / tex_size.y
	var inner_tex_size: Vector2
	var inner_tex_pos: Vector2
	if tex_aspect > rect_aspect:
		inner_tex_size = Vector2(rect_size.x, rect_size.x / tex_aspect)
		inner_tex_pos = Vector2(0, (rect_size.y - inner_tex_size.y) / 2)
	else:
		inner_tex_size = Vector2(rect_size.y * tex_aspect, rect_size.y)
		inner_tex_pos = Vector2((rect_size.x - inner_tex_size.x) / 2, 0)
	return Vector2(
			(p.x - inner_tex_pos.x) * tex_size.x / inner_tex_size.x,
			(p.y - inner_tex_pos.y) * tex_size.y / inner_tex_size.y)


func _on_clear_button_pressed() -> void:

	var old_size := texture.size
	var old_data := texture.get_image().get_data()
	var ur := DoodleTexturePlugin.instance.get_undo_redo()
	ur.create_action("Clear texture")
	ur.add_do_method(texture, "clear")
	ur.add_undo_method(texture, "set_data", old_size.x, old_size.y, old_data)
	ur.commit_action()


func _on_swap_button_pressed() -> void:

	var ur := DoodleTexturePlugin.instance.get_undo_redo()
	ur.create_action("Swap colors")
	ur.add_do_property(texture, "foreground_color", texture.background_color)
	ur.add_do_property(texture, "background_color", texture.foreground_color)
	ur.add_undo_property(texture, "foreground_color", texture.foreground_color)
	ur.add_undo_property(texture, "background_color", texture.background_color)
	ur.commit_action()
