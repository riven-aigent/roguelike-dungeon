class_name ShopUI extends Control

const ShopSystem = preload("res://scripts/shop_system.gd")

signal item_purchased(item_type)
signal shop_closed

@onready var gold_display: Label = $GoldDisplay
@onready var items_container: VBoxContainer = $ItemsContainer
@onready var close_button: Button = $CloseButton

var current_gold: int = 0
var shop_items: Array = []  # Array of ShopSystem.ShopItem

func _ready() -> void:
	close_button.pressed.connect(_on_close_button_pressed)

func show_shop(gold: int, items: Array) -> void:
	current_gold = gold
	shop_items = items
	_update_display()
	show()

func _update_display() -> void:
	gold_display.text = "Gold: " + str(current_gold)
	
	# Clear existing items
	for child in items_container.get_children():
		child.queue_free()
	
	# Add shop items
	for i in range(shop_items.size()):
		var shop_item: ShopSystem.ShopItem = shop_items[i]
		
		# Create item button
		var item_button: Button = Button.new()
		item_button.text = shop_item.name + " - " + str(shop_item.price) + "g"
		item_button.tooltip_text = shop_item.description
		
		# Disable if not enough gold
		if current_gold < shop_item.price:
			item_button.disabled = true
			item_button.add_theme_color_override("font_disabled_color", Color(0.6, 0.6, 0.6))
		
		# Connect purchase signal
		item_button.pressed.connect(_on_item_purchased.bind(i))
		items_container.add_child(item_button)
		
		# Add description label below the button
		var desc_label: Label = Label.new()
		desc_label.text = shop_item.description
		desc_label.set("theme_override/font_size", 12)
		desc_label.set("theme_override/font_color", Color(0.7, 0.7, 0.7))
		desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
		desc_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		items_container.add_child(desc_label)
		
		# Add some spacing
		var spacer: Control = Control.new()
		spacer.custom_minimum_size = Vector2(0, 8)
		items_container.add_child(spacer)

func _on_item_purchased(index: int) -> void:
	if index < shop_items.size():
		var shop_item: ShopSystem.ShopItem = shop_items[index]
		if current_gold >= shop_item.price:
			current_gold -= shop_item.price
			emit_signal("item_purchased", shop_item.type)
			_update_display()

func _on_close_button_pressed() -> void:
	hide()
	emit_signal("shop_closed")