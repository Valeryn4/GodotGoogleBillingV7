extends "res://addons/godot_billing_service/billing_private.gd"


const GOOGLE_TYPE_IN_APP := 1
const GOOGLE_TYPE_SUBS := 3



const GODOT_GOOGLE_BILLING := "GodotGoogleBilling"

var _google_billing = null
var _inited := false
var _license_key: String = ""

func _to_string() -> String:
	return "[GodotBillingPrivateAndroid]"

func _init(param: Dictionary = {}).(param) -> void :
	print(self, " GodotBillingPrivateAndroid init from param - ", param)
	store = Store.GooglePlayMarket
	vendor = Vendor.Google
	is_auto_update_product = false
	if param :
		_license_key = param.get("google_license_key", "")
	if Engine.has_singleton(GODOT_GOOGLE_BILLING) :
		_google_billing = Engine.get_singleton(GODOT_GOOGLE_BILLING)
		_google_billing.connect("prices_in_app_update", self, "_on_prices_in_app_update", [], CONNECT_DEFERRED)
		_google_billing.connect("product_purchased",    self, "_on_product_purchased",    [], CONNECT_DEFERRED)
		_google_billing.connect("product_restored",     self, "_on_product_restored",     [], CONNECT_DEFERRED)
		_google_billing.connect("product_failed",       self, "_on_product_failed",       [], CONNECT_DEFERRED)
	
	if not _google_billing :
		push_error("%s google is null!" % str(self))
		return


###############################################################################
##### CALLBACKS ###############################################################
###############################################################################

func _on_prices_in_app_update(data) -> void :
	if data :
		
		print(self, " data prices update: ", data)
		
		var data_dict := data as Dictionary
		var sku := data_dict["sku"] as String
		
		var product := get_products().get_product_from_sku(sku)
		if not product :
			product = create_product(sku)
		
		
		var type_product := data_dict["type_product"] as int
		if type_product == GOOGLE_TYPE_IN_APP :
			product.product_type = ProductType.InApp
		elif type_product == GOOGLE_TYPE_SUBS :
			product.product_type == ProductType.Subs
		
		product.display_name  = data_dict["title"]         as String
		product.description   = data_dict["description"]   as String
		product.display_price = data_dict["price"]         as String
		product.price         = data_dict["price_amount"]  as float
		product.currency_code = data_dict["currency_code"] as String
		product.optional["billing_cycle_count"] = data_dict["billing_cycle_count"] as int
		product.optional["billing_period"] = data_dict["billing_period"] as String
		product.optional["recurrence_mode"] = data_dict["recurrence_mode"] as int
		
		product.is_valid = true
		
		emit_signal("update_product", product)
		emit_signal("update_products")
	else :
		push_error("%s price update data is null!" % str(self))

func _on_product_purchased(data) -> void :
	if data :
		print(self, " data purchased: ", data)
		var transaction_dict := data as Dictionary
		
		var sku := transaction_dict["sku"] as String
		var product := get_products().get_product_from_sku(sku)
		if not product :
			push_error("%s product from sku %s not found!" % [str(self), sku])
		var transaction := GodotBillingTransaction.new()
		transaction.product = product
		
		var transaction_id := transaction_dict["order_id"] as String
		transaction.transaction_id = transaction_id
		transaction.status = StatusCode.Purchased
		var json_str := transaction_dict.get("json", "") as String
		if json_str and json_str.length() > 2:
			var json_dirct := JSON.parse(json_str).result as Dictionary
			if json_dirct :
				transaction.optional["json"] = json_dirct
				transaction.purchased_date = int(json_dirct.get("purchaseTime", 0))
		
		transaction.optional["is_acknowledged"] = transaction_dict["is_acknowledged"]
		transaction.optional["purchase_state"] = transaction_dict["purchase_state"]
		transaction.optional["purchase_token"] = transaction_dict["purchase_token"]
		transaction.optional["signature"] = transaction_dict["signature"]
		transaction.optional["package_name"] = transaction_dict["package_name"]
		transaction.optional["response_code"] = transaction_dict["response_code"]
		
		transactions.add_transaction(transaction)
		emit_signal("update_transaction", transaction)
		emit_signal("update_transactions")
		emit_signal("purchase_success", transaction)
	else :
		push_error("%s price update data is null!" % str(self))


func _on_product_restored(data) -> void :
	if data :
		print(self, " data restored: ", data)
		var transaction_dict := data as Dictionary
		
		var sku := transaction_dict["sku"] as String
		var product := get_products().get_product_from_sku(sku)
		var transaction := GodotBillingTransaction.new()
		transaction.product = product
		
		var transaction_id := transaction_dict["order_id"] as String
		transaction.transaction_id = transaction_id
		transaction.status = StatusCode.Purchased
		
		var json_str := transaction_dict.get("json", "") as String
		if json_str :
			var json_dirct := JSON.parse(json_str).result as Dictionary
			if json_dirct and json_str.length() > 2:
				transaction.optional["json"] = json_dirct
				transaction.purchased_date = int(json_dirct.get("purchaseTime", 0))
		
		transaction.optional["is_acknowledged"] = transaction_dict["is_acknowledged"]
		transaction.optional["purchase_state"] = transaction_dict["purchase_state"]
		transaction.optional["purchase_token"] = transaction_dict["purchase_token"]
		transaction.optional["signature"] = transaction_dict["signature"]
		transaction.optional["package_name"] = transaction_dict["package_name"]
		transaction.optional["response_code"] = transaction_dict["response_code"]
		transactions.add_transaction(transaction)
		emit_signal("update_transaction", transaction)
		emit_signal("update_transactions")
	else :
		push_error("%s price update data is null!" % str(self))

func _on_product_failed(data) -> void :
	if data :
		push_warning("%s data failed: %s" % [str(self), str(data)])
		var transaction_dict := data as Dictionary
		
		var sku := transaction_dict["sku"] as String
		var product := get_products().get_product_from_sku(sku)
		var transaction := GodotBillingTransaction.new()
		transaction.product = product
		
		var transaction_id := transaction_dict["order_id"] as String
		transaction.transaction_id = transaction_id
		transaction.status = StatusCode.Error
		
		var json_str: String = transaction_dict.get("json", "") as String
		if json_str and json_str.length() > 2:
			var json_dirct := JSON.parse(json_str).result as Dictionary
			if json_dirct :
				transaction.optional["json"] = json_dirct
				transaction.purchased_date = int(json_dirct.get("purchaseTime", 0))
		
		transaction.optional["is_acknowledged"] = transaction_dict["is_acknowledged"]
		transaction.optional["purchase_state"] = transaction_dict["purchase_state"]
		transaction.optional["purchase_token"] = transaction_dict["purchase_token"]
		transaction.optional["signature"] = transaction_dict["signature"]
		transaction.optional["package_name"] = transaction_dict["package_name"]
		transaction.optional["response_code"] = transaction_dict["response_code"]
		transactions.add_transaction(transaction)
		emit_signal("update_transaction", transaction)
		emit_signal("update_transactions")
		emit_signal("purchase_failed", transaction)
		
	else :
		push_error("%s price update data is null!" % str(self))
###############################################################################
#### OVERRIDE #################################################################
###############################################################################



## override
## requested all products contain is product container
func _request_products() -> void :
	print(self, " request products!")
	if not _google_billing :
		push_error("%s google is null!" % str(self))
		return
	
	if _inited :
		push_warning("this billing is inited!")
		return
	_inited = true
	
	
	var consumables := PoolStringArray()
	var non_consumables := PoolStringArray()
	var subs := PoolStringArray()
	for obj in products.get_products() :
		var product := obj as __Product
		assert(product, "obj is not Product type")
		if product.product_type == ProductType.Subs :
			subs.append(product.sku)
		else :
			if product.is_consumable :
				consumables.append(product.sku)
			else :
				non_consumables.append(product.sku)
	
	print(self, " build from non_consumables", non_consumables)
	print(self, " build from consumables", consumables)
	print(self, " build from subs", subs)
	_google_billing.build(non_consumables, consumables, subs, _license_key)
	
	

## override
## request product from list
func _request_products_from_list(list: Array) -> void :
	print(self, " request products from list!")
	if list.empty() :
		push_warning("%s Request product failed. Poduct list is empty" % str(self))
		return
	
	if not _google_billing :
		push_error("%s google is null" % str(self))
		return
	
	if _inited :
		push_warning("this billing is inited!")
		return
	_inited = true
	
	var consumables := []
	var non_consumables := []
	var subs := []
	for obj in list :
		var product := obj as __Product
		assert(product, "obj is not Product type")
		if product.product_type == ProductType.Subs :
			subs.append(product.sku)
		else :
			if product.is_consumable :
				consumables.append(product.sku)
			else :
				non_consumables.append(product.sku)
	
	print(self, " build from non_consumables", non_consumables)
	print(self, " build from consumables", consumables)
	print(self, " build from subs", subs)
	_google_billing.build(non_consumables, consumables, subs, _license_key)

## override
## request single product
func _request_product(product: __Product) -> void :
	print(self, " request product from product!", product)
	if not _google_billing :
		push_error("%s google is null!" % str(self))
		return
	
	_request_products_from_list([product])

## override
func _request_purchase(product: __Product, _quantity: int) -> void :
	print(self, " request purchase from product!")
	if not _google_billing :
		push_error("%s google is null!" % str(self))
		return
	
	if product.product_type == ProductType.InApp :
		_google_billing.purchase(product.sku)
	else :
		_google_billing.subscribe(product.sku)

## override
func _restore_purchase() -> void :
	print(self, " restore purchase from product!")
	if not _google_billing :
		push_error("%s google is null!" % str(self))
		return
	
	push_warning("Google non restored!")

##override
## consume product
func _consume_transaction(_transaction: __ProductTransaction) -> void :
	if not _google_billing :
		push_error("%s google is null!" % str(self))
		return
	
	assert(false, "is not impl")



###############################################################################
###############################################################################
###############################################################################

