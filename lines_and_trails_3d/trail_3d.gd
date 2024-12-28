@tool

class_name Trail3D
extends Line3D


enum LimitMode {
	TIME,
	LENGTH
}


@export_range(0.01, 1.0) var max_section_length: float = 0.1:
	get: return max_section_length
	set(value):
		if max_section_length == value:
			return
		max_section_length = value
		if _auto_rebuild and Engine.is_editor_hint():
			rebuild()
@export var limit_mode: LimitMode = LimitMode.TIME:
	get: return limit_mode
	set(value):
		if limit_mode == value:
			return
		limit_mode = value
		set_process(value == LimitMode.TIME)
		notify_property_list_changed()
		if _auto_rebuild and Engine.is_editor_hint():
			_step()
@export var time_limit: float = 0.25:
	get: return time_limit
	set(value):
		if time_limit == value:
			return
		time_limit = value
		if _auto_rebuild and Engine.is_editor_hint():
			_step()
@export var length_limit: float = 1.0:
	get: return length_limit
	set(value):
		if length_limit == value:
			return
		length_limit = value
		if _auto_rebuild and Engine.is_editor_hint():
			_step()
@export var pin_texture: bool = false:
	get: return pin_texture
	set(value):
		if pin_texture == value:
			return
		pin_texture = value
		notify_property_list_changed()
		if _auto_rebuild and Engine.is_editor_hint():
			rebuild()

var _times: PackedFloat64Array
var _last_pinned_u: float


func _ready() -> void:

	use_global_space = true
	process_priority = 9999

	rebuild()


func _validate_property(property: Dictionary) -> void:

	match property.name:
		"time_limit":
			if limit_mode != LimitMode.TIME:
				property.usage &= ~PROPERTY_USAGE_EDITOR
		"length_limit":
			if limit_mode != LimitMode.LENGTH:
				property.usage &= ~PROPERTY_USAGE_EDITOR
		"points", "curve_normals":
			property.usage = PROPERTY_USAGE_NONE
		"use_global_space":
			property.usage = PROPERTY_USAGE_NONE
		"texture_offset":
			if pin_texture:
				property.usage = PROPERTY_USAGE_NONE
		"pin_texture":
			if texture_tile_mode == TextureTileMode.RATIO:
				property.usage = PROPERTY_USAGE_NONE
		_:
			super._validate_property(property)


func clear() -> void:

	_times.clear()
	_last_pinned_u = 0
	super.clear()


func _process(_delta: float) -> void:

	if limit_mode == LimitMode.TIME:
		_step()


func _step() -> void:

	if not is_inside_tree() or not is_node_ready():
		return

	_auto_rebuild = false

	if not use_global_space:
		use_global_space = true

	var tf := global_transform
	var pos := tf.origin
	var up := tf.basis.y
	var time := Time.get_ticks_msec() / 1000.0

	while points.size() < 2:
		points.insert(0, pos)
		curve_normals.insert(0, up)
	while _times.size() < 2:
		_times.insert(0, time)

	points[0] = pos
	curve_normals[0] = up
	_times[0] = time

	if points.size() >= 2:

		var leading := points[1]
		var from_leading := pos - leading
		var dist_from_leading := from_leading.length()

		if pin_texture:
			texture_offset = -_last_pinned_u - dist_from_leading
		else:
			_last_pinned_u = -texture_offset - dist_from_leading

		if dist_from_leading > max_section_length:
			points.insert(1, pos)
			curve_normals.insert(1, up)
			_times.insert(1, time)
			_last_pinned_u += dist_from_leading

	if limit_mode == LimitMode.LENGTH:

		var last_index := points.size() - 1
		var total_length := 0.0
		for i in last_index:
			total_length += points[i].distance_to(points[i + 1])

		var extra_length := total_length - length_limit

		while extra_length > 0:
			var last_point := points[last_index]
			var second_last_point := points[last_index - 1]
			var last_section_length := last_point.distance_to(second_last_point)
			if last_section_length > extra_length:
				var shortened_section_length := last_section_length - extra_length
				points[last_index] = second_last_point + (last_point - second_last_point) * (shortened_section_length / last_section_length)
			else:
				points.remove_at(last_index)
				curve_normals.remove_at(last_index)
				_times.remove_at(last_index)
				last_index -= 1
			extra_length -= last_section_length

	elif limit_mode == LimitMode.TIME:

		var last_index := _times.size() - 1
		var total_time := _times[0] - _times[last_index]
		var extra_time := total_time - time_limit

		while extra_time > 0:
			var last_time := _times[last_index]
			var second_last_time := _times[last_index - 1]
			var last_section_duration := second_last_time - last_time
			if last_section_duration > extra_time:
				var last_point := points[last_index]
				var second_last_point := points[last_index - 1]
				var shortened_section_duration := last_section_duration - extra_time
				var shortened_ratio := shortened_section_duration / last_section_duration
				points[last_index] = second_last_point + (last_point - second_last_point) * shortened_ratio
				_times[last_index] = second_last_time + (last_time - second_last_time) * shortened_ratio
			else:
				points.remove_at(last_index)
				curve_normals.remove_at(last_index)
				_times.remove_at(last_index)
				last_index -= 1
			extra_time -= last_section_duration

	_auto_rebuild = true

	rebuild()


# VIRTUAL
func _on_transform_changed() -> void:

	if limit_mode == LimitMode.LENGTH:
		_step()
