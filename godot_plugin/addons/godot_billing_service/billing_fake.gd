extends "res://addons/godot_billing_service/billing_private.gd"



func _init(param: Dictionary = {}).(param) -> void :
	store = Store.None
	vendor = Vendor.None
	


###############################################################################
#### OVERRIDE #################################################################
###############################################################################



## override
## requested all products contain is product container
func _request_products() -> void :
	var skus := []
	
	var tree := (Engine.get_main_loop() as SceneTree)
	yield(tree.create_timer(rand_range(0.5, 2.0)), "timeout")
	
	for obj in products.get_products() :
		var product := obj as __Product
		assert(product, "obj is not Product type")
		skus.append(product.sku)
		
		create_product(product.sku).is_valid = true
		emit_signal("update_product", product)
	
	emit_signal("update_products")
	pass

## override
## request product from list
func _request_products_from_list(list: Array) -> void :
	if list.empty() :
		push_warning("%s Request product failed. Poduct list is empty" % str(self))
		return
	
	var tree := (Engine.get_main_loop() as SceneTree)
	yield(tree.create_timer(rand_range(0.5, 2.0)), "timeout")
	
	var skus := []
	for obj in list :
		var product := obj as __Product 
		assert(product, "obj is not Product type")
		skus.append(product.sku)
		
		create_product(product.sku).is_valid = true
		emit_signal("update_product", product)
	
	emit_signal("update_products")
	
	
	

## override
## request single product
func _request_product(product: __Product) -> void :
	_request_products_from_list([product])


## override
func _request_purchase(product: __Product, quantity: int) -> void :
	var tree := (Engine.get_main_loop() as SceneTree)
	yield(tree.create_timer(rand_range(0.5, 2.0)), "timeout")
	
	
	var trans_exists := get_transactions().get_transactions_from_products(product)
	for trans in trans_exists :
		var transaction_exist: GodotBillingTransaction = trans as GodotBillingTransaction
		if transaction_exist.status == StatusCode.Purchased :
			emit_signal("purchase_success", transaction_exist)
			return
	
	
	var transaction := GodotBillingTransaction.new()
	transaction.product = product
	
	transaction.transaction_id = UUID.v4()
	transaction.status = StatusCode.Purchased
	get_transactions().add_transaction(transaction)
	emit_signal("update_transaction", transaction)
	emit_signal("update_transactions")
	
	emit_signal("purchase_success", transaction)

## override
func _restore_purchase() -> void :
	pass

##override
## consume product
func _consume_transaction(_transaction: __ProductTransaction) -> void :
	assert(false, "is not impl")



###############################################################################
###############################################################################
###############################################################################

