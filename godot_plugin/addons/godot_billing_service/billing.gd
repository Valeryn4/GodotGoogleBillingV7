extends Node
class_name GodotBilling, "res://addons/godot_billing_service/icn_coin1_32.png"

const __BillingPrivate              := preload("res://addons/godot_billing_service/billing_private.gd")
const __Product                     := preload("res://addons/godot_billing_service/product.gd")
const __ProductContainer            := preload("res://addons/godot_billing_service/product_container.gd")
const __ProductTransaction          := preload("res://addons/godot_billing_service/product_transaction.gd")
const __ProductTransactionContainer := preload("res://addons/godot_billing_service/product_transaction_container.gd")


const Store       := __BillingPrivate.Store
const Vendor      := __BillingPrivate.Vendor

const ProductType := __BillingPrivate.ProductType
const PRODUCT_TYPE_IN_APP  := __BillingPrivate.PRODUCT_TYPE_IN_APP
const PRODUCT_TYPE_SUBS    := __BillingPrivate.PRODUCT_TYPE_SUBS
const PRODUCT_TYPE_INVALID := __BillingPrivate.PRODUCT_TYPE_INVALID

const StatusCode := __BillingPrivate.StatusCode
const STATUS_PURCHASED           := __BillingPrivate.STATUS_PURCHASED
const STATUS_PURCHASE_DEFERRED   := __BillingPrivate.STATUS_PURCHASE_DEFERRED
const STATUS_REVOCATION  := __BillingPrivate.STATUS_REVOCATION
const STATUS_REFOUND     := __BillingPrivate.STATUS_REFOUND
const STATUS_CANCELED    := __BillingPrivate.STATUS_CANCELED
const STATUS_ERROR       := __BillingPrivate.STATUS_ERROR
const STATUS_UNVALIAVBLE := __BillingPrivate.STATUS_UNVALIAVBLE


signal update_product(product)
signal update_products()
signal update_transaction(transaction)
signal update_transactions()

signal purchased(transaction)
signal purchase_failed(transaction)
signal purchase_success(transaction)


var _billing_private: __BillingPrivate = null

var is_auto_update_product := false setget set_is_auto_update_product, get_is_auto_update_product
func set_is_auto_update_product(val) -> void :
	if _billing_private :
		_billing_private.is_auto_update_product = val
func get_is_auto_update_product() -> bool :
	if _billing_private :
		return _billing_private.is_auto_update_product
	return false

var vendor: int = Vendor.None setget , get_vendor
func get_vendor() -> int :
	if _billing_private :
		return _billing_private.vendor
	
	return Vendor.None

var store: int = Store.None setget , get_store
func get_store() -> int :
	if _billing_private :
		return _billing_private.store
	return Store.None

func _to_string() -> String:
	return "[GodotBilling]"

func _init(param: Dictionary = {}) -> void:
	print(self, " GodotBilling init from param - ", param)
	
	if OS.get_name() in ["Android"] :
		_billing_private = load("res://addons/godot_billing_service/billing_android.gd").new(param)
	elif OS.get_name() in ["OSX", "MacOS", "iOS", "tvOS"] :
		_billing_private = load("res://addons/godot_billing_service/billing_ios.gd").new(param)
	else :
		_billing_private = load("res://addons/godot_billing_service/billing_fake.gd").new(param)
	
	if not _billing_private :
		push_error("%s billing private is null!" % str(self))
		return
	
	_billing_private.connect("update_product", self, "_on_update_product")
	_billing_private.connect("update_products", self, "_on_update_products")
	
	_billing_private.connect("update_transaction", self, "_on_update_transaction")
	_billing_private.connect("update_transactions", self, "_on_update_transactions")
	
	_billing_private.connect("purchased", self, "_on_purchased")
	_billing_private.connect("purchase_success", self, "_on_purchase_success")
	_billing_private.connect("purchase_failed", self, "_on_purchase_failed")
	pass

func _on_update_product(product: __Product) -> void :
	emit_signal("update_product", product)

func _on_update_products() -> void :
	emit_signal("update_products")

func _on_update_transaction(transaction: __ProductTransaction) -> void :
	emit_signal("update_transaction", transaction)

func _on_update_transactions() -> void :
	emit_signal("update_transactions")

func _on_purchased(transaction: __ProductTransaction) -> void :
	emit_signal("purchased", transaction)

func _on_purchase_success(transaction: __ProductTransaction) -> void :
	emit_signal("purchase_success", transaction)

func _on_purchase_failed(transaction: __ProductTransaction) -> void :
	emit_signal("purchase_failed", transaction)

###############################################################################
###############################################################################
###############################################################################

static func create_product_without_billing(sku: String) -> __Product :
	return __BillingPrivate.create_product_without_billing(sku)

func create_product(sku: String, type: int = PRODUCT_TYPE_INVALID, consumable := false, renewable := false) -> __Product :
	if not _billing_private :
		push_error("%s billing private is null!" % str(self))
		return null
	
	return _billing_private.create_product(sku, type, consumable, renewable)

func consume_transaction(transaction: __ProductTransaction) -> void :
	if not _billing_private :
		push_error("%s billing private is null!" % str(self))
		return
	
	_billing_private.consume_transaction(transaction)

func request_products() -> void :
	if not _billing_private :
		push_error("%s billing private is null!" % str(self))
		return
	
	_billing_private.request_products()

func request_products_from_list(list: Array) -> void :
	if not _billing_private :
		push_error("%s billing private is null!" % str(self))
		return
		
	_billing_private.request_products_from_list(list)

func request_purchase(product: __Product, quantity: int = 1) -> void :
	if not _billing_private :
		push_error("%s billing private is null!" % str(self))
		return
	
	_billing_private.request_purchase(product, quantity)

func restore_purchase() -> void :
	if not _billing_private :
		push_error("%s billing private is null!" % str(self))
		return
	
	_billing_private.restore_purchase()


###############################################################################
##### FAST GETTER #############################################################
###############################################################################


func get_products() -> __ProductContainer :
	if not _billing_private :
		push_error("%s billing private is null!" % str(self))
		return null
	
	return _billing_private.get_products()

func get_transactions() -> __ProductTransactionContainer :
	if not _billing_private :
		push_error("%s billing private is null!" % str(self))
		return null
	
	return _billing_private.get_transactions()

func get_products_in_app() -> Array :
	if not _billing_private :
		push_error("%s billing private is null!" % str(self))
		return []
	
	return _billing_private.get_products_in_app()

func get_products_subs() -> Array :
	if not _billing_private :
		push_error("%s billing private is null!" % str(self))
		return []
	
	return _billing_private.get_products_subs()

func get_products_purchased() -> Array :
	if not _billing_private :
		push_error("%s billing private is null!" % str(self))
		return []
	
	return _billing_private.get_products_purchased()

func is_purchased(product: __Product) -> bool :
	if not _billing_private :
		push_error("%s billing private is null!" % str(self))
		return false
	
	return _billing_private.is_purchased(product)

func get_products_active_subs() -> Array :
	if not _billing_private :
		push_error("%s billing private is null!" % str(self))
		return []
	
	return _billing_private.get_products_active_subs()

func get_transaction_purchased() -> Array :
	if not _billing_private :
		push_error("%s billing private is null!" % str(self))
		return []
	
	return _billing_private.get_transaction_purchased()

func get_transaction_active_subs() -> Array :
	if not _billing_private :
		push_error("%s billing private is null!" % str(self))
		return []
	
	return _billing_private.get_transaction_active_subs()



