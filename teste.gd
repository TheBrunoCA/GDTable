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
var data1 = [
	{ 'id':0, 'nome':'Bruno', 'health':100 },
	{ 'id':1, 'nome':'Leo', 'health':100 },
	{ 'id':2, 'nome':'Fabio', 'health':100 },
	{ 'id':3, 'nome':'Carlos', 'health':100 },
	{ 'id':04, 'nome':'Tonho', 'health':100 },
]

func _ready() -> void:
	var table:GDTable = %Table
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
