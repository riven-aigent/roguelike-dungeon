class_name ShopUI extends Control

const ShopSystem = preload("res://scripts/shop_system.gd")

signal item_purchased(item_type)
signal shop_closed

@onready var gold_display: Label = $ShopPanel/GoldDisplay
@onready var items_container: VBoxContainer = $ShopPanel/ScrollContainer/ItemsContainer
@onready var close_button: Button = $ShopPanel/CloseButton
@onready var continue_button: Button = $ShopPanel/ContinueButton
@onready var vignette: ColorRect = $VignetteOverlay

var current_gold: int = 0
var shop_items: Array = []  # Array of ShopSystem.ShopItem


func _ready() -> void:
	close_button.pressed.connect(_on_close_button_pressed)
	continue_button.pressed.connect(_on_close_button_pressed)
	# Click on vignette to close
	vignette.gui_input.connect(_on_vignette_input)


func _on_vignette_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_on_close_button_pressed()


func show_shop(gold: int, items: Array) -> void:
	current_gold = gold
	shop_items = items
	_update_display()
	show()


func _update_display() -> void:
	gold_display.text = "💰 Gold: " + str(current_gold)

	# Clear existing items
	for child in items_container.get_children():
		child.queue_free()

	# Add shop items
	for i in range(shop_items.size()):
		var shop_item: ShopSystem.ShopItem = shop_items[i]

		# Create item container
		var item_container: PanelContainer = PanelContainer.new()
		item_container.custom_minimum_size = Vector2(340, 80)
		
		# Create inner vbox
		var vbox: VBoxContainer = VBoxContainer.new()
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		item_container.add_child(vbox)

		# Create item button
		var item_button: Button = Button.new()
		item_button.text = shop_item.name + " - " + str(shop_item.price) + "g"
		item_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		item_button.custom_minimum_size = Vector2(280, 35)

		# Disable if not enough gold
		if current_gold < shop_item.price:
			item_button.disabled = true
			item_button.add_theme_color_override("font_disabled_color", Color(0.6, 0.6, 0.6))

		# Connect purchase signal
		item_button.pressed.connect(_on_item_purchased.bind(i))
		vbox.add_child(item_button)

		# Add description label below the button
		var desc_label: Label = Label.new()
		desc_label.text = shop_item.description
		desc_label.set("theme_override/font_size", 11)
		desc_label.set("theme_override/font_color", Color(0.8, 0.8, 0.8))
		desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
		desc_label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		desc_label.custom_minimum_size = Vector2(300, 0)
		desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(desc_label)

		items_container.add_child(item_container)


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
