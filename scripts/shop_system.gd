class_name ShopSystem

# Shop item types
enum ShopItemType {
	HEALTH_POTION,
	STRENGTH_POTION, 
	SHIELD_SCROLL,
	GOLD_BAG,
	REVIVAL_AMULET,
	TELEPORT_SCROLL,
	BLESSING_SCROLL
}

# Shop item data structure
class ShopItem:
	var type: ShopItemType
	var name: String
	var description: String
	var price: int
	var unlocked: bool = true
	
	func _init(t: ShopItemType, n: String, desc: String, p: int):
		type = t
		name = n
		description = desc
		price = p

# Available shop items
var available_items: Array[ShopItem] = []
var persistent_data: PersistentData

func initialize(persistent_ref: PersistentData) -> void:
	persistent_data = persistent_ref
	_setup_shop_items()

func _setup_shop_items() -> void:
	available_items.clear()
	
	# Always available items
	available_items.append(ShopItem.new(ShopItemType.HEALTH_POTION, "Health Potion", "Restores 8 HP", 25))
	available_items.append(ShopItem.new(ShopItemType.STRENGTH_POTION, "Strength Potion", "+1 Attack permanently", 40))
	available_items.append(ShopItem.new(ShopItemType.SHIELD_SCROLL, "Shield Scroll", "+1 Defense permanently", 40))
	available_items.append(ShopItem.new(ShopItemType.GOLD_BAG, "Gold Bag", "Gain 20 gold", 15))
	
	# Unlockable items
	if persistent_data.shop_unlocks.get("revival_amulet", false):
		available_items.append(ShopItem.new(ShopItemType.REVIVAL_AMULET, "Revival Amulet", "Revive with 1 HP if you die (one-time use)", 100))
		
	if persistent_data.shop_unlocks.get("teleport_scroll", false):
		available_items.append(ShopItem.new(ShopItemType.TELEPORT_SCROLL, "Teleport Scroll", "Instantly teleport to stairs", 60))
		
	if persistent_data.shop_unlocks.get("blessing_scroll", false):
		available_items.append(ShopItem.new(ShopItemType.BLESSING_SCROLL, "Blessing Scroll", "Gain 50 XP instantly", 75))

func get_random_shop_items(count: int = 3) -> Array[ShopItem]:
	var unlocked_items: Array[ShopItem] = []
	for item in available_items:
		unlocked_items.append(item)
	
	var selected_items: Array[ShopItem] = []
	var attempts: int = 0
	while selected_items.size() < count and attempts < 100 and unlocked_items.size() > 0:
		attempts += 1
		var index: int = randi() % unlocked_items.size()
		selected_items.append(unlocked_items[index])
		unlocked_items.remove_at(index)
	
	return selected_items

# Process purchase - returns true if successful
func purchase_item(item: ShopItem, current_gold: int) -> bool:
	if current_gold >= item.price:
		return true
	return false