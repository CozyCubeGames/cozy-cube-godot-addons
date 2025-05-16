@tool
class_name AreaLight3D
extends Node3D


@export var area_size: Vector2 = Vector2(1, 1):
	get: return area_size
	set(value):
		if value == area_size:
			return
		area_size = value
		if Engine.is_editor_hint() and is_node_ready():
			_refresh()
			update_gizmos()
@export_range(0.0, 4096.0, 0.01, "exp") var area_range: float = 5.0:
	get: return area_range
	set(value):
		if value == area_range:
			return
		area_range = value
		if Engine.is_editor_hint() and is_node_ready():
			_refresh()
@export_range(0.1, 5.0, 0.1) var area_resolution: float = 2.0:
	get: return area_resolution
	set(value):
		if value == area_resolution:
			return
		area_resolution = value
		if Engine.is_editor_hint() and is_node_ready():
			_refresh()
@export var light_color: Color = Color.WHITE:
	get: return light_color
	set(value):
		if value == light_color:
			return
		light_color = value
		if Engine.is_editor_hint() and is_node_ready():
			_refresh()
			update_gizmos()
@export_range(0.0, 100.0) var light_energy: float = 1.0:
	get: return light_energy
	set(value):
		if value == light_energy:
			return
		light_energy = value
		if Engine.is_editor_hint() and is_node_ready():
			_refresh()
			update_gizmos()
@export_range(5.0, 180.0, 0.1) var light_angle: float = 90.0:
	get: return light_angle
	set(value):
		if value == light_angle:
			return
		light_angle = value
		if Engine.is_editor_hint() and is_node_ready():
			_refresh()


func _ready() -> void:

	if Engine.is_editor_hint():
		_refresh()
	else:
		queue_free()


func _refresh() -> void:

	if owner != EditorInterface.get_edited_scene_root():
		return

	for i in range(get_child_count() - 1, -1, -1):
		var child := get_child(i)
		if child is not SpotLight3D:
			child.free()

	var starting_child_count: int = get_child_count()
	var row_count := maxi(1, roundi(area_size.y * area_resolution))
	var col_count := maxi(1, roundi(area_size.x * area_resolution))
	var sublight_count: int = 0

	var x_inc := area_size.x / col_count
	var y_inc := area_size.y / row_count
	var corner := Vector3(
			-area_size.x / 2 + x_inc / 2,
			-area_size.y / 2 + y_inc / 2,
			0)

	for row in row_count:
		for col in col_count:

			var sublight: SpotLight3D
			if sublight_count < starting_child_count:
				sublight = get_child(sublight_count)
			else:
				sublight = SpotLight3D.new()
				add_child(sublight)
				sublight.owner = self.owner

			sublight.name = "sublight_" + str(sublight_count + 1)
			sublight.visible = false
			sublight.light_bake_mode = Light3D.BAKE_STATIC
			sublight.spot_angle = light_angle
			sublight.light_color = light_color
			sublight.spot_angle_attenuation = 0.001
			sublight.spot_range = area_range
			sublight.position = corner + Vector3(col * x_inc, row * y_inc, 0)
			sublight.basis = Basis.IDENTITY

			sublight_count += 1

	var sublight_energy := light_energy * (area_size.x * area_size.y) * (90.0 / light_angle) / sublight_count
	for sublight in get_children():
		sublight.light_energy = sublight_energy

	for i in range(get_child_count() - 1, sublight_count - 1, -1):
		get_child(i).free()
