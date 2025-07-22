class_name Inventory
extends Resource

# Use Inventory Resolution to manage interactions..
# if item couldn't be added to inventory for some reason, shouldn't remove item from existence
enum Resolution {
	SUCCESS,
	NO_ITEM, AT_CAPACITY, IS_EMPTY,
	NOT_FOUND, OUT_OF_BOUNDS, DUPLICATE,
	NO_CHANGE
}

@export var has_max_limit:bool = true:
	set(limit):
		has_max_limit = limit
		if has_max_limit and collection.size() > max_size:
			resize_collection(max_size)
@export var max_size:int = 30:
	set(size):
		max_size = size
		if has_max_limit and collection.size() > size:
			resize_collection(size)
@export var collection:Dictionary[Item, int] = {}:
	set(items):
		# If somebody tries to manually bypass size restrictions, this should prevent that
		if has_max_limit and items.size() > max_size:
			resize_collection(max_size)
		collection = items

func add_item_to_collection(item:Item, amount:int = 1) -> Resolution:
	if !item:
		return Resolution.NO_ITEM
	if has_max_limit and collection.size() >= max_size:
		return Resolution.AT_CAPACITY
	
	# Special Case Handling
	if amount < 1 and collection.has(item):
		if amount < 0:
			return remove_item_from_collection(item, -amount)
		return Resolution.NO_CHANGE
	
	# Add the item(s)
	if collection.has(item) and item.is_stackable:
		collection[item] += amount
	else:
		collection[item] = amount
	return Resolution.SUCCESS

func remove_item_from_collection(item:Item, amount:int = 1, remove_all:bool = false) -> Resolution:
	if collection.is_empty():
		return Resolution.IS_EMPTY
	if !item:
		return Resolution.NO_ITEM
	if !collection.has(item):
		return Resolution.NOT_FOUND
	
	# Special Case Handling
	if amount > collection[item]:
		remove_all = true
	if amount < 1:
		if amount < 0:
			return add_item_to_collection(item, -amount)
		return Resolution.NO_CHANGE
	
	# Remove the item(s)
	if remove_all:
		collection.erase(item)
	else:
		if collection[item] > amount:
			collection[item] -= amount
		else:
			collection.erase(item)
	return Resolution.SUCCESS

func replace_item_in_collection(item_to_remove:Item, item_to_add:Item, amount:int = 1, copy_count:bool = false, not_found_do_add:bool = false) -> Resolution:
	if collection.is_empty():
		if !not_found_do_add:
			return Resolution.IS_EMPTY
	if !item_to_remove:
		if !not_found_do_add:
			return Resolution.NO_ITEM
	if has_max_limit and collection.size() >= max_size:
		if !collection.has(item_to_remove):
			return Resolution.AT_CAPACITY
	# NOTE: Currently, if same items to add/remove, just use add or remove func...
	if item_to_remove == item_to_add:
		var diff:int = collection[item_to_remove] - collection[item_to_add]
		if diff > 0:
			return add_item_to_collection(item_to_remove, diff)
		elif diff < 0:
			return remove_item_from_collection(item_to_remove, diff)
		return Resolution.NO_CHANGE
	# Pass the checks, add the item_to_add and remove item_to_remove (if found/present)
	if collection.has(item_to_remove):
		if item_to_add.is_stackable:
			if copy_count:
				collection[item_to_add] = collection[item_to_remove]
			else:
				collection[item_to_add] = amount
		else:
			collection[item_to_add] = amount
		collection.erase(item_to_remove)
	else:
		# not_found_do_add == true
		collection[item_to_add] = amount
	# If not stopped in other checks, item was found or not_found_do_add == true
	return Resolution.SUCCESS

enum ResId { ITEM, RESOLUTION }
# If dict returned is empty, assume no change or failure/error based on rules
# NOTE: Use this function is adding multiple different items as one-ofs...
func add_items_to_collection(items:Array[Item] = []) -> Dictionary[int, Dictionary]:
	var resolutions:Dictionary[int, Dictionary] = {}
	if !items or items.is_empty():
		return resolutions
	
	var attempt:int = 0
	for item:Item in items:
		attempt += 1
		if has_max_limit and collection.size() >= max_size and !collection.has(item):
			resolutions.set(attempt, {ResId.ITEM : item, ResId.RESOLUTION : Resolution.AT_CAPACITY})
		else:
			if collection.has(item):
				collection[item] += 1
			else:
				collection[item] = 1
			resolutions.set(attempt, {ResId.ITEM : item, ResId.RESOLUTION : Resolution.SUCCESS})
	return resolutions

func remove_items_from_collection(items:Array[Item] = [], allow_partial_removal:bool = false, remove_all:bool = false) -> Dictionary[int, Dictionary]:
	var resolutions:Dictionary[int, Dictionary] = {}
	if !items or items.is_empty():
		return {}
	
	var attempt:int = 0
	var removals:Dictionary[int, Item] = {}
	for item:Item in items:
		attempt += 1
		if !collection.has(item):
			if !allow_partial_removal:
				return {}
			else:
				resolutions.set(attempt, {ResId.ITEM : item, ResId.RESOLUTION : Resolution.NOT_FOUND})
				continue
		
		if remove_all:
			collection.erase(item)
		else:
			# Remove items one-by-one
			if collection[item] > 1:
				collection[item] -= 1
			else:
				collection.erase(item)
		resolutions.set(attempt, {ResId.ITEM : item, ResId.RESOLUTION : Resolution.SUCCESS})
	return resolutions

func resize_collection(new_size:int=max_size) -> void:
	if collection.size() > new_size:
		var skip:int = 0
		while collection.size() > new_size or skip >= collection.size():
			var it:Item = collection.keys()[collection.size() - 1 - skip]
			if !it.is_key_item:
				collection.erase(it)
			else:
				skip += 1

func clear_collection() -> void:
	collection.clear()
