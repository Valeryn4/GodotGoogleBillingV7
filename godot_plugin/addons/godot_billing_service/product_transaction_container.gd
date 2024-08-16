extends Reference

const __ProductTransaction := preload("res://addons/godot_billing_service/product_transaction.gd")
const __Product            := preload("res://addons/godot_billing_service/product.gd")

const StatusCode := __ProductTransaction.StatusCode

signal updated()
var _transactions := {}


func add_transaction(transaction: __ProductTransaction) -> void :
	_add_transaction(transaction)
	emit_signal("updated")


func add_transactions(transaction_list: Array) -> void :
	for transaction in transaction_list :
		_add_transaction(transaction)
	emit_signal("updated")


func erase_transaction(transaction: __ProductTransaction) -> void :
	if _erase_transaction(transaction) :
		emit_signal("updated")



func get_transactions() -> Array :
	return _transactions.values()

func get_transactions_from_status(status: int) -> Array :
	var res := []
	for value in _transactions.values() :
		var transaction := value as __ProductTransaction
		if transaction.status == status :
			res.append(transaction)
	return res


func get_transactions_purchased() -> Array :
	return get_transactions_from_status(StatusCode.Purchased)


func get_transactions_active_subs() -> Array :
	var res := []
	for value in _transactions.values() :
		var transaction := value as __ProductTransaction
		if transaction.product.product_type == __Product.ProductType.Subs :
			if transaction.status == StatusCode.Purchased :
				res.append(transaction)
	return res




func get_products_from_status(status: int) -> Array :
	var res := []
	for value in _transactions.values() :
		var transaction := value as __ProductTransaction
		if transaction.status == status :
			res.append(transaction.product)
	return res


func get_products_purchased() -> Array :
	return get_products_from_status(StatusCode.Purchased)

func has_product_is_purchased(product: __Product) -> bool :
	for value in _transactions.values() :
		var transaction := value as __ProductTransaction
		if transaction.product == product and transaction.status == StatusCode.Purchased :
			return true
	
	return false

func get_products_active_subs() -> Array :
	var res := []
	for value in _transactions.values() :
		var transaction := value as __ProductTransaction
		if transaction.product.product_type == __Product.ProductType.Subs :
			if transaction.status == StatusCode.Purchased :
				res.append(transaction.product)
	return res



func get_transactions_from_products(product: __Product) -> Array :
	var res := []
	for value in _transactions.values() :
		var transaction := value as __ProductTransaction
		if transaction.product == product :
			res.append(transaction)
	return res

func get_transaction_from_id(transaction_id: String) -> __ProductTransaction :
	return _transactions.get(transaction_id, null)







func _add_transaction(transaction: __ProductTransaction) -> void :
	assert(transaction, "transaction is null!")
	assert(transaction.product, " transaction %s invalid product" % transaction.transaction_id)
	
	var exists_transaction: __ProductTransaction = _transactions.get(transaction.transaction_id) as __ProductTransaction
	if exists_transaction :
		exists_transaction.copy_from(transaction)
	else :
		_transactions[transaction.transaction_id] = transaction

func _erase_transaction(transaction: __ProductTransaction) -> bool :
	assert(transaction, "transaction is null!")
	return _transactions.erase(transaction.transaction_id)
