extends Reference

signal updated()

const __Product := preload("res://addons/godot_billing_service/product.gd")

var _product_list := {}


func add_product(product: __Product) -> void :
	_add_product(product)
	emit_signal("updated")

func add_products(product_list: Array) -> void :
	for product in product_list :
		_add_product(product)
	emit_signal("updated")




func erace_product(product: __Product) -> void :
	assert(product, " product is null")
	if _erace_product(product.sku) :
		emit_signal("updated")

func erace_product_from_sku(sku: String) -> void :
	if _erace_product(sku) :
		emit_signal("updated")




func get_products() -> Array :
	return _product_list.values()

func get_products_valid() -> Array :
	var arr := []
	for value in _product_list.values() :
		var product: __Product = value as __Product
		if product :
			if product.is_valid :
				arr.append(product)
	return arr

func get_products_invalid() -> Array :
	var arr := []
	for value in _product_list.values() :
		var product: __Product = value as __Product
		if product :
			if not product.is_valid :
				arr.append(product)
	return arr

func get_products_from_type(type: int) -> Array :
	var arr := []
	for value in _product_list.values() :
		var product: __Product = value as __Product
		if product :
			if product.is_valid :
				if product.product_type == type :
					arr.append(product)
	return arr

func get_products_in_app() -> Array :
	return get_products_from_type(__Product.ProductType.InApp)

func get_products_subs() -> Array :
	return get_products_from_type(__Product.ProductType.Subs)




func get_product_from_sku(sku: String) -> __Product :
	return _product_list.get(sku, null) as __Product

func get_product(product: __Product) -> __Product :
	assert(product, "product is null")
	
	return _product_list.get(product.sku, null) as __Product


func has_product(product: __Product) -> bool :
	return _product_list.has(product.sku)


func is_empty() -> bool :
	return _product_list.empty()

func is_not_empty() -> bool :
	return not is_empty()




func _add_product(product: __Product) -> void :
	assert(product, " product is null!")
	
	var exists_product: __Product = _product_list.get(product.sku) as __Product
	if exists_product :
		exists_product.copy_from(product)
	else :
		_product_list[product.sku] = product

func _erace_product(sku: String) -> bool :
	return _product_list.erase(sku)




