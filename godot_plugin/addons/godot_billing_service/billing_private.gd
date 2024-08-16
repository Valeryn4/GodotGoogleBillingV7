extends Reference
class_name GodotBillingPrivate

const __Product                     := preload("res://addons/godot_billing_service/product.gd")
const __ProductContainer            := preload("res://addons/godot_billing_service/product_container.gd")
const __ProductTransaction          := preload("res://addons/godot_billing_service/product_transaction.gd")
const __ProductTransactionContainer := preload("res://addons/godot_billing_service/product_transaction_container.gd")


enum Store {
	None,
	AppleAppStore,
	GooglePlayMarket,
}

enum Vendor {
	None,
	Apple,
	Google,
}



const ProductType := __Product.ProductType

const PRODUCT_TYPE_IN_APP  := ProductType.InApp
const PRODUCT_TYPE_SUBS    := ProductType.Subs
const PRODUCT_TYPE_INVALID := ProductType.INVALID



const StatusCode := __ProductTransaction.StatusCode

const STATUS_PURCHASED           := StatusCode.Purchased
const STATUS_PURCHASE_DEFERRED   := StatusCode.PurchaseDeferred
const STATUS_REVOCATION  := StatusCode.Revocation
const STATUS_REFOUND     := StatusCode.Refound
const STATUS_CANCELED    := StatusCode.Canceled
const STATUS_ERROR       := StatusCode.Error
const STATUS_UNVALIAVBLE := StatusCode.Unvaliavble



signal update_product(product)
signal update_products()
signal update_transaction(transaction)
signal update_transactions()

signal purchased(transaction)
signal purchase_failed(transaction)
signal purchase_success(transaction)


var products:     __ProductContainer            = __ProductContainer.new()
var transactions: __ProductTransactionContainer = __ProductTransactionContainer.new()

var is_auto_update_product := false

var store: int = Store.None
var vendor: int = Vendor.None

func _init(param: Dictionary = {}) -> void:
	print(self, " GodotBillingPrivate init from param - ", param)
	pass

## virtual
## requested all products contain is product container
func _request_products() -> void :
	assert(false, " abstract, is not impl")

## virtual
## request product from list
func _request_products_from_list(_list: Array) -> void :
	assert(false, " abstract, is not impl")

## virtual
## request single product
func _request_product(_product: __Product) -> void :
	assert(false, " abstract, is not impl")

## virtual
## start process purchase
func _request_purchase(_product: __Product, _quantity: int) -> void :
	assert(false, " abstract, is not impl")

## virtual
## restored transaction
func _restore_purchase() -> void :
	assert(false, " abstract, is not impl")

##virtual
## consume product
func _consume_transaction(_transaction: __ProductTransaction) -> void :
	assert(false, " abstract, is not impl")

###############################################################################
###############################################################################
###############################################################################

static func create_product_without_billing(sku: String) -> __Product :
	return __Product.new(sku)

func create_product(sku: String, type: int = PRODUCT_TYPE_INVALID, consumable := false, renewable := false) -> __Product :
	var product := products.get_product_from_sku(sku)
	if not product :
		product = __Product.new(sku, type, consumable, renewable)
		products.add_product(product)
	
	if is_auto_update_product :
		_request_product(product)
	return product

func consume_transaction(transaction: __ProductTransaction) -> void :
	_consume_transaction(transaction)

func request_products() -> void :
	_request_products()

func request_products_from_list(list: Array) -> void :
	_request_products_from_list(list)

func request_purchase(product: __Product, quantity: int = 1) -> void :
	_request_purchase(product, quantity)

func restore_purchase() -> void :
	_restore_purchase()


###############################################################################
##### FAST GETTER #############################################################
###############################################################################


func get_products() -> __ProductContainer :
	return products

func get_transactions() -> __ProductTransactionContainer :
	return transactions

func get_products_in_app() -> Array :
	return products.get_products_in_app()

func get_products_subs() -> Array :
	return products.get_products_subs()

func get_products_purchased() -> Array :
	return transactions.get_products_purchased()

func is_purchased(product: __Product) -> bool :
	return transactions.has_product_is_purchased(product)

func get_products_active_subs() -> Array :
	return transactions.get_products_active_subs()

func get_transaction_purchased() -> Array :
	return transactions.get_transactions_purchased()

func get_transaction_active_subs() -> Array :
	return transactions.get_transactions_active_subs()
