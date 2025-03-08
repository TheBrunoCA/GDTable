GDTable - A Flexible and Customizable Table Component for Godot

GDTable is a table component designed for the Godot Engine, enabling developers to easily display, edit, and manage tabular data in their projects.
Key Features

    Dynamic Data Binding:
    Bind your table to arrays of objects or dictionaries, with support for nested properties using dot notation (e.g., player.stats.health).

    Customizable Columns:
    Define columns with custom names, formatters, sorting algorithms, and editing capabilities.

    Pagination Support:
    Easily handle large datasets with built-in pagination.

    Sorting and Filtering:
    Sort data by any column, with support for custom sorting algorithms.

    Editable Cells:
    Enable or disable cell editing on a per-column basis. GDTable ensures data integrity by allowing reversible formatting for editable fields.

    Event-Driven Design:
    Built-in signals for common events like item selection, double-clicks, and data changes, making it easy to integrate with your game logic.

    Fully Documented:
    Comprehensive documentation and examples make it easy to get started.

Example Usage
```gdscript
extends Control

class user:
	var id
	var nome
	var stat
	func _init(i,n,s):
		id = i
		nome = n
		stat = s

class stats:
	var health:int
	func _init(h):
		health = h

var data = [
	user.new(0, 'Bruno', stats.new(100)),
	user.new(1, 'Leo', stats.new(80)),
	user.new(2, 'Leandro', stats.new(110)),
	user.new(3, 'Fabio', stats.new(90)),
	user.new(4, 'Carlos', stats.new(80)),
	user.new(5, 'Joao', stats.new(105)),
	user.new(10, 'Joao', stats.new(105)),
]

func _ready() -> void:
	var table:GDTable = %Table #With a GDTable already in place
	table.set_columns_definitions([
		GDTable.ColumnDefinition.new(
			'id', 'ID'
		),
		GDTable.ColumnDefinition.new(
			'nome', 'NOME', true, true
		),
		GDTable.ColumnDefinition.new(
			'stat.health', 'HEALTH', true
		)
	])
	table.current_page = 1
	table.current_per_page = -1
	table.set_data_source(data)
	table.item_double_clicked.connect(print_item)


func print_item(item):
	print('
	id: %s
	nome: %s
	health: %s' % [
		item.get('id'),
		item.get('nome'),
		item.get('health'),
	])

```

Note
This Readme was made using AI, so even though I read and edited it, it may have incorrect info.
