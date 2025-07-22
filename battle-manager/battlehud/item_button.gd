extends Button

signal item_selected(item: Item)

@export var current_item: Item:
	set(value):
		print("Setting item resource:", value)
		current_item = value
		if is_inside_tree():
			_update_display()
var count:int = 1

func _ready():
	print("Button _ready called")
	if current_item:
		print("Initial item: ", current_item)
		_update_display()

func setup(item: Item, amount:int = 1) -> void:
	print("Setup called with item: ", item)
	current_item = item
	count = amount
	_update_display()

func _update_display() -> void:
	print("Updating display for current_item:", current_item)
	var container = $HBoxContainer
	var name_label = container.get_node_or_null("HBox#ItemName")
	var count_label = container.get_node_or_null("HBox#ItemCount") 
	var icon_rect = container.get_node_or_null("HBox#Icon")
	
	if current_item is Item:
		name_label.text = current_item.item_name
		count_label.text = "x" + str(count)
		if current_item.icon:
			icon_rect.texture = current_item.icon

func _pressed():
	print("Button pressed, emitting skill:", current_item)
	item_selected.emit(current_item)
