@tool
class_name GDTable
extends Tree
## A table for displaying and modifying data
##
## To use, first set the [member _columns_definitions] property
## with [method set_columns_definitions] method
## with an array of [Table.ColumnDefinition].
##
## Afterwards use [method set_data_source] with an
## array of dictionaries or objects to be shown.
##
## Can optionally use pagination setting [member current_page] and
## [member current_per_page].

#region Signals

## Signal emitted right before the table reloads.
## Can be used to cancel the reloading by emitting [signal request_reload_cancel]
signal reloading

## Signal emitted by the user to cancel a table [method reload]
signal request_reload_cancel

## Signal emitted by [method set_data_source]
signal data_source_changed

## Signal emitted when an [member _data_source] item is changed, does not cause a reloading
signal data_source_item_changed(item)

## Signal emitted when a item is double clicked
signal item_double_clicked(item)

##

#endregion

#region Public Properties

## If set to true, everytime the signal [signal data_source_changed] is emitted,
## the table will be reloaded
var auto_reload:bool = true

## The current page being shown, does not reload the table if changed.
## To reflect the change, call [method reload] manually
var current_page:int = 1

## The current numbers of items per page being shown, does not reload the table if changed.
## To reflect the change, call [method reload] manually
var current_per_page:int = -1

#endregion

#region Private Properties

# Stores the data being shown
var _data_source: Array

# If true, the table will not reload next time [method reload] is called.
var _do_not_reload:bool = false

# The current column that the data is sorted by
var _sorted_by_column:int = -1

# Whether the data is sorted ascending
var _sorted_asc:bool = false

# The root [TreeItem] ot the [Tree]
var _root:TreeItem

# Stores the columns definitions
var _columns_definitions:Array[ColumnDefinition]

#endregion


#region Private Static Methods

# Retrieves the value of the property from an object or value from the key if dictionary.
# Accepts dot notation like "obj = player, path = stats.health"
# [param obj] is the object or dictionary from which the property or key is part of.
# [param path] is the key or path to the desired property.
# [param default] is the default value returned.
static func _get_property(obj, path:String, default) -> Variant:
	var parts: PackedStringArray = path.split('.', false)
	var current_value = obj

	for part:String in parts:

		if current_value is Dictionary:
			if not current_value.has(part) or not current_value:
				push_error(
					'%s Does not have a %s property' % [part, current_value]
				)
				return default

		elif current_value is Object:
			if not part in current_value or not is_instance_valid(current_value):
				push_error(
					'%s Does not have a %s property' % [part, current_value]
				)
				return default

		elif current_value is Array:
			if not part.is_valid_int():
				push_error('current_value is an array but part is not a int.')
				return default

			var idx:int = part.to_int()
			if not idx < current_value.size():
				push_error('index is bigger than array size.')
				return default

			current_value = current_value.get(idx)
			continue

		elif current_value is Callable:
			current_value = current_value.call()
			continue

		current_value = current_value.get(part)

	return current_value


# Sets the value of the property or dictionary.
# Accepts dot notation like "obj = player, path = stats.health"
# [param obj] is the object or dictionary from which the property or key is part of.
# [param path] is the key or path to the desired property.
# [param value] The value to be set.
static func _set_property(obj, path: String, value: Variant) -> void:
	var parts: PackedStringArray = path.split('.')
	var current = obj

	for i:int in range(parts.size() - 1):
		var part:String = parts[i]
		if not part in current:
			push_error('Property %s not found in %s.' % [part, current])
			return
		current = current.get(part)
	var final_part:String = parts[-1]
	current.set(final_part, value)


#endregion

#region Overriden Built-ins

func _enter_tree() -> void:
	column_titles_visible = true
	hide_folding = true
	hide_root = true
	select_mode = Tree.SELECT_MULTI


func _ready() -> void:
	request_reload_cancel.connect(_on_request_reload_cancel)
	data_source_changed.connect(_on_data_source_changed)
	column_title_clicked.connect(_on_column_title_clicked)
	item_edited.connect(_on_item_edited)
	item_activated.connect(_on_item_activated)

#endregion

#region Public Methods

## Retrives the data_source from [member _data_source]
func get_data_source() -> Array:
	return _data_source


## Sets the [member _data_source] and emits the [signal data_source_changed] signal.
## if [param emit_signal] is false, no signal is emitted.
func set_data_source(new_data:Array, emit_signal:bool = true) -> void:
	if _data_source == new_data:
		return

	_data_source = new_data

	if emit_signal:
		data_source_changed.emit()


## Sets the [member _column_definitions] property. Does not reload the table.
func set_columns_definitions(col_defs:Array[ColumnDefinition]) -> void:
	_columns_definitions = col_defs


## Reloads the table.
## Set [param page] to set the page for pagination.
## Set [param per_page] to set how many items will be shown on each page.
## Params defaults to whatever is set on [member current_page] and [member current_per_page].
func reload(page:int = current_page, per_page:int = current_per_page) -> void:

	reloading.emit()

	if _do_not_reload:
		return

	clear()

	_root = create_item()

	if _data_source.is_empty():
		return

	if _columns_definitions.is_empty():
		push_error('Columns Definitions must be set before reloading.')
		return

	columns = _columns_definitions.size()

	for col_idx:int in _columns_definitions.size():
		var col_def:ColumnDefinition = _columns_definitions[col_idx]

		if col_idx == _sorted_by_column:
			if _sorted_by_column >= 0:
				if _sorted_asc:
					set_column_title(_sorted_by_column, '%s ▼' % col_def.column_name)
				else:
					set_column_title(_sorted_by_column, '%s ▲' % col_def.column_name)
		else:
			set_column_title(col_idx, col_def.column_name)

		set_column_clip_content(col_idx, col_def.important)
		set_column_expand(col_idx, col_def.important)
		set_column_custom_minimum_width(col_idx, col_def.minimum_width)

	if page > 1 and per_page < 0:
		push_error('page cannot be bigger than 1 if per_page is lesser than 1.')
		return

	var begin_idx:int = (
			0 if page == 1
			else (page - 1) * per_page
	)

	var end_idx:int = (
			0x7FFFFFFF if per_page == -1
			else per_page * page
	)

	if begin_idx >= _data_source.size():
		return

	var paged_source:Array = _data_source.slice(begin_idx, end_idx)

	for item_idx:int in paged_source.size():
		var item = paged_source[item_idx]
		var t_item:TreeItem = create_item(_root)
		var props:Array[PropertyInfo] = _get_properties(item)

		for p_idx:int in props.size():
			var prop:PropertyInfo = props[p_idx]
			var column:ColumnDefinition = _columns_definitions[p_idx]

			t_item.set_text(p_idx, column.formatter.call(prop.property_value))
			t_item.set_editable(p_idx, column.editable)
			t_item.set_meta('item_idx', begin_idx + item_idx)

	current_page = page
	current_per_page = per_page


## Returns all the selected items
func get_selected_items() -> Array:
	var selected_items:Array[TreeItem]
	var last_selected:TreeItem = get_next_selected(null)

	while last_selected != null:
		selected_items.append(last_selected)
		last_selected = get_next_selected(last_selected)

	var data_source_items:Array = []
	for selected_item:TreeItem in selected_items:
		var item_idx:int = selected_item.get_meta('item_idx')

		if item_idx == null:
			push_error('For some reason, item_idx is null.')
			return []

		var data_source_item = _data_source[item_idx]
		data_source_items.append(data_source_item)

	return data_source_items


#endregion

#region Private Methods

# Sorts [member _data_source] by the specified column
func _sort_by_column(column_idx:int, asc:bool) -> void:
	var column:ColumnDefinition = _columns_definitions[column_idx]

	_data_source.sort_custom(column.sort_algorithm.bind(asc, column))
	_sorted_by_column = column_idx
	_sorted_asc = asc

	data_source_changed.emit()


# Get all the properties from an object which are in [member _columns_definitions]
func _get_properties(obj) -> Array[PropertyInfo]:
	if _columns_definitions.is_empty():
		push_error('_columns_definitions should not be empty here.')
		return []

	var props:Array[PropertyInfo] = []

	for column:ColumnDefinition in _columns_definitions:

		props.append(PropertyInfo.new(column.source_name, column.formatter.call(
			_get_property(obj, column.source_name, column.default_value))))

	return props


# Callback for when the signal [signal data_source_changed] is emitted
func _on_data_source_changed() -> void:
	if auto_reload:
		reload()


# Callback for when the signal [signal request_reload_cancel] is emitted
func _on_request_reload_cancel() -> void:
	_do_not_reload = true


# Callback for when the [signal Tree.item_edited] is emitted
func _on_item_edited() -> void:
	var item: TreeItem = get_edited()
	var item_idx:int = item.get_meta('item_idx')

	if item_idx == null:
		push_error('For some reason, item_idx is null.')
		return

	var data_source_item = _data_source[item_idx]

	for column_idx: int in _columns_definitions.size():
		var column: ColumnDefinition = _columns_definitions[column_idx]
		if not column.editable:
			continue

		_set_property(
				data_source_item,
				column.source_name,
				column.reverse_formatter.call(item.get_text(column_idx))
		)
		item.set_text(column_idx, column.formatter.call(
				_get_property(
						data_source_item,
						column.source_name,
						column.default_value
				)
			)
		)

	data_source_item_changed.emit(data_source_item)


# Callback for when a column title is clicked
func _on_column_title_clicked(col_idx:int, mouse_idx:int) -> void:
	if mouse_idx == 1:
		if _sorted_by_column == col_idx:
			_sorted_asc = not _sorted_asc
		else:
			_sorted_asc = true
		_sort_by_column(col_idx, _sorted_asc)


# Callback for when a item is double clicked
func _on_item_activated() -> void:
	var item: TreeItem = get_next_selected(null)
	var item_idx:int = item.get_meta('item_idx')

	if item_idx == null:
		push_error('For some reason, item_idx is null.')
		return

	var data_source_item = _data_source[item_idx]

	item_double_clicked.emit(data_source_item)





#endregion

#region Internal Classes

class PropertyInfo:
	## Utility class to hold objects properties

	## The name of the property
	var property_name:String

	## The value of the property
	var property_value:Variant

	## [param _property_name] The name of the property
	## [param _property_value] The value of the property
	func _init(
		_property_name:String
		, _property_value:Variant
	) -> void:
		property_name = _property_name
		property_value = _property_value


class ColumnDefinition:
	## Class to hold definitions regarding the columns.


	## The name or path of the key or property that will be shown in this column.
	var source_name:String

	## The name that will be shown in the table.
	var column_name:String:
		get:
			return (
					column_name if not column_name.is_empty()
					else source_name
			)


	## Whether this column is editable.
	var editable:bool

	## Whether this column is important and will try to show its entire value.
	var important:bool

	## This columns minimum width.
	var minimum_width:int

	## This column default value.
	var default_value:Variant

	## The Callable that will be used to get the value that will be shown.
	## Must accept one argument, the original value, and return the formatted value.
	var formatter:Callable

	## The Callable that will be used to set the value back from the table into the data_source.
	## Must accept one argument, the table value, and return the formatted value.
	var reverse_formatter:Callable

	## The Callable that will be used to sort the data by this column.
	## Must accept two values that will be compared, a boolean whether its ascending or not
	## and a [Table.ColumnDefinition] object.
	var sort_algorithm:Callable

	## [param _source_name] The name or path of the key or property that will be shown in this column.
	## [param _column_name] The name that will be shown in the table.
	## [param _editable] Whether this column is editable.
	## [param _important] Whether this column is important and will try to show its entire value.
	## [param _minimum_width] This columns minimum width.
	## [param _default_value] This column default value.
	## [param _formatter] The Callable that will be used to get the value that will be shown.
	## Must accept one argument, the original value, and return the formatted value.
	## [param _sort_algorithm] The Callable that will be used to sort the data by this column.
	## Must accept two values that will be compared, a boolean whether its ascending or not
	## and a [Table.ColumnDefinition] object.
	func _init(
		_source_name:String
		, _column_name:String = ''
		, _editable:bool = false
		, _important:bool = false
		, _minimum_width:int = 100
		, _default_value:Variant = 'N/A'
		, _formatter:Callable = func(x): return str(x)
		, _reverse_formatter:Callable = func (x): return x
		, _sort_algorithm:Callable = default_sorter
	) -> void:
		source_name = _source_name
		column_name = _column_name
		editable = _editable
		important = _important
		minimum_width = _minimum_width
		default_value = _default_value
		formatter = _formatter
		reverse_formatter = _reverse_formatter
		sort_algorithm = _sort_algorithm


	## A default sorting algorithm.
	static func default_sorter(a, b, asc:bool, column_def:ColumnDefinition) -> bool: ##TODO Rethink this
		var av = GDTable._get_property(a, column_def.source_name, column_def.default_value)
		var bv = GDTable._get_property(b, column_def.source_name, column_def.default_value)
		if typeof(av) != typeof(bv):
			push_error(
				'Error while sorting. %s from %s is not the same type of %s from %s' % [
					column_def.source_name, a, column_def.source_name, b
				]
			)
			return false
		return (av < bv) if asc else (av > bv)

#endregion
