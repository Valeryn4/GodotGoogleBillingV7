extends "res://addons/godot_billing_service/billing_private.gd"

const STORE_KIT_2 := "GodotStoreKit2"

var store_kit_2 = null

func _init(param: Dictionary = {}).(param) -> void :
	store = Store.AppleAppStore
	vendor = Vendor.Apple
	if Engine.has_singleton(STORE_KIT_2) :
		store_kit_2 = Engine.get_singleton(STORE_KIT_2)
		store_kit_2.connect("update_products_list",    self, "_on_store_kit_update_products_list", [], CONNECT_DEFERRED)
		store_kit_2.connect("update_transaction_list", self, "_on_store_kit_update_transaction_list", [], CONNECT_DEFERRED)
		store_kit_2.connect("purchased",               self, "_on_store_kit_purchased", [], CONNECT_DEFERRED)
		store_kit_2.connect("store_sync_completed",    self, "_on_store_kit_store_sync_completed", [], CONNECT_DEFERRED)
		store_kit_2.connect("purchase_deferred",       self, "_on_store_kit_store_kit_purchase_deferred", [], CONNECT_DEFERRED)
		
		store_kit_2.purchase_deferred_force()


###############################################################################
##### CALLBACKS ###############################################################
###############################################################################


func _on_store_kit_store_kit_purchase_deferred(sku: String) -> void :
	var transaction := __ProductTransaction.new()
	transaction.product = products.get_product_from_sku(sku)
	transaction.transaction_id = "deferred_" + sku
	transaction.status = STATUS_PURCHASE_DEFERRED
	transaction.quantity = 1
	transactions.add_transaction(transaction)
	emit_signal("update_transaction", transaction)
	emit_signal("update_transactions")


func _on_store_kit_update_products_list(product_list) -> void :
	if product_list :
		for product_dict in product_list :
			var dict: Dictionary = product_dict as Dictionary
			
			var display_name = dict.display_name as String
			var description = dict.description as String
			var display_price = dict.display_price as String
			
			var price = (dict.price as String).to_float()
			var sku = dict.sku as String
			var currency = dict.currency as String
			var currency_code = dict.currency_code as String
			
			var product: __Product = products.get_product_from_sku(sku)
			if not product :
				product = __Product.new()
			
			product.sku = sku
			product.price = price
			product.currency = currency
			product.currency_code = currency_code
			product.display_name = display_name
			product.description = description
			product.display_price = display_price
			product.is_valid = true
			
			products.add_product(product)
			
			emit_signal("update_product", product)
	
	emit_signal("update_products")

func _parse_transaction(transaction, status: int) -> __ProductTransaction :
	var dict: Dictionary = transaction as Dictionary
	var sku: String = dict.sku
	
	var quantity = (dict.quantity as String).to_int()
	var original_id = dict.original_id
	var purchased_date = int(dict.purchased_date)
	var transaction_id = dict.transaction_id
	var bundle_id = dict.bundle_id
	var is_upgraded: bool = true if dict.is_upgraded == "yes" else false
	var is_revocation: bool = true if dict.is_revocation == "yes" else false
	var revocation_date = int(dict.revocation_date)
	var revocation_reason = dict.revocation_reason
	var ownership_type = dict.ownership_type
	var expiration_date = int(dict.expiration_date)
	
	var product_transaction := __ProductTransaction.new()
	product_transaction.status = status
	
	product_transaction.product = products.get_product_from_sku(sku)
	product_transaction.transaction_id = transaction_id
	product_transaction.quantity = quantity as int
	product_transaction.purchased_date = purchased_date
	product_transaction.quantity = 1
	
	product_transaction.optional["original_id"] = original_id
	product_transaction.optional["bundle_id"] = bundle_id
	product_transaction.optional["expiration_date"] = expiration_date
	product_transaction.optional["revocation_date"] = revocation_date
	product_transaction.optional["revocation_reason"] = revocation_reason
	product_transaction.optional["is_upgraded"] = is_upgraded
	product_transaction.optional["ownership_type"] = ownership_type
	
	
	if is_revocation :
		product_transaction.status = STATUS_REVOCATION
	elif is_upgraded :
		product_transaction.status = STATUS_UNVALIAVBLE
	
	return product_transaction

func _on_store_kit_update_transaction_list(transaction_list) -> void :
	if transaction_list :
		for transaction in transaction_list :
			
			var product_transaction := _parse_transaction(transaction, STATUS_PURCHASED)
			transactions.add_transaction(transaction)
			emit_signal("update_transaction", transaction)
	
	emit_signal("update_transactions")


func _on_store_kit_purchased(err_code: int, err_text: String, transaction: Dictionary) -> void :
	if transaction :
		
		var product_transaction := _parse_transaction(transaction, STATUS_PURCHASED)
		if err_code == OK :
			product_transaction.status = STATUS_PURCHASED
			transactions.add_transaction(product_transaction)
			emit_signal("purchased", product_transaction)
			emit_signal("purchase_success", product_transaction)
			
		else :
			product_transaction.status = STATUS_ERROR
			transactions.add_transaction(product_transaction)
			emit_signal("purchased", product_transaction)
			emit_signal("purchase_failed", product_transaction)
			


func _on_store_kit_store_sync_completed() -> void :
	print(self, " store kit 2 sync completed")
	if store_kit_2 :
		store_kit_2.restore_all()






###############################################################################
#### OVERRIDE #################################################################
###############################################################################



## override
## requested all products contain is product container
func _request_products() -> void :
	var skus := []
	for obj in products.get_products() :
		var product := obj as __Product
		assert(product, "obj is not Product type")
		skus.append(product.sku)
	
	store_kit_2.request_products(skus)

## override
## request product from list
func _request_products_from_list(list: Array) -> void :
	if list.empty() :
		push_warning("%s Request product failed. Poduct list is empty" % str(self))
		return
	
	if not store_kit_2 :
		push_error("%s Store Kit is null" % str(self))
		return
	
	var skus := []
	for obj in list :
		var product := obj as __Product 
		assert(product, "obj is not Product type")
		skus.append(product.sku)
	
	store_kit_2.request_products(skus)

## override
## request single product
func _request_product(product: __Product) -> void :
	store_kit_2.request_products([product.sku])

## override
func _request_purchase(product: __Product, quantity: int) -> void :
	store_kit_2.purchase_product(product.sku, quantity)

## override
func _restore_purchase() -> void :
	if store_kit_2 :
		store_kit_2.restore_all()

##override
## consume product
func _consume_transaction(_transaction: __ProductTransaction) -> void :
	assert(false, "is not impl")



###############################################################################
###############################################################################
###############################################################################

