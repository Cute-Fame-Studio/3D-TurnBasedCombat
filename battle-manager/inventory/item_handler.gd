extends Node

func use_item(item:Item, target:Battler) -> void:
	print("Use item ", item.item_name, " on target: ", target.character_name)
