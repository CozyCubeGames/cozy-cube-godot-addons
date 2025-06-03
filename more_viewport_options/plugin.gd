@tool
extends EditorPlugin


var _extensions: Array[ViewportExtension]


func _enter_tree() -> void:

	for i in 4:
		_extensions.append(ViewportExtension.new(EditorInterface.get_editor_viewport_3d(i)))


func _exit_tree() -> void:

	for ext in _extensions:
		if ext:
			ext.free()

	_extensions.clear()


class ViewportExtension extends Object:


	const ALIGN_TO_TRANSFORM_ID: int = 259823
	const COPY_ID: int = 259824
	const PASTE_ID: int = 259825

	var vp: SubViewport
	var menu: PopupMenu
	var focus_id: int

	static var has_copy: bool
	static var copied_tf: Transform3D
	static var copied_fov: float


	func _init(p_vp: Viewport) -> void:

		vp = p_vp
		var menu_button := vp.get_parent().get_parent().get_child(1).get_child(0).get_child(0) as MenuButton
		if not menu_button:
			return
		menu = menu_button.get_popup()
		if not menu:
			return

		for i in menu.item_count:
			if menu.get_item_text(i) == "Focus Selection":
				focus_id = menu.get_item_id(i)
				break

		menu.add_item("Align View with Transform", ALIGN_TO_TRANSFORM_ID)
		menu.add_item("Copy View", COPY_ID)
		menu.add_item("Paste View", PASTE_ID)

		menu.id_pressed.connect(_on_menu_id_pressed)


	func _notification(what: int) -> void:

		if what == NOTIFICATION_PREDELETE:
			if menu:
				menu.id_pressed.disconnect(_on_menu_id_pressed)
				menu.remove_item(menu.get_item_index(ALIGN_TO_TRANSFORM_ID))
				menu.remove_item(menu.get_item_index(COPY_ID))
				menu.remove_item(menu.get_item_index(PASTE_ID))


	func _get_target_node() -> Node3D:

		var nodes := EditorInterface.get_selection().get_transformable_selected_nodes()
		for node in nodes:
			if node is Node3D:
				return node
		return null


	func _align_to(tf: Transform3D) -> void:

		var cam := vp.get_camera_3d()
		cam.global_transform = tf
		await RenderingServer.frame_post_draw

		var temp_node := Node3D.new()
		temp_node.transform = tf
		temp_node.position += (temp_node.position - cam.global_position)
		vp.add_child(temp_node)

		var old_selected_nodes := EditorInterface.get_selection().get_selected_nodes()
		EditorInterface.get_selection().clear()
		EditorInterface.get_selection().add_node(temp_node)

		menu.id_pressed.emit(focus_id)

		EditorInterface.get_selection().clear()
		for n in old_selected_nodes:
			EditorInterface.get_selection().add_node(n)

		temp_node.free()


	func _on_menu_id_pressed(id: int) -> void:

		match id:
			ALIGN_TO_TRANSFORM_ID:
				var target := _get_target_node()
				if target:
					_align_to(target.global_transform)
			COPY_ID:
				has_copy = true
				var cam := vp.get_camera_3d()
				copied_tf = cam.global_transform
				copied_fov = cam.fov
			PASTE_ID:
				if has_copy:
					_align_to(copied_tf)
					vp.get_camera_3d().fov = copied_fov
