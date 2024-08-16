extends Node

var game := SampleGame.new()
var billing := GodotBilling.new()

var product_dlc      := billing.create_product("com.example.dlc",     GodotBilling.PRODUCT_TYPE_IN_APP, false, false)
var product_gold_100 := billing.create_product("com.example.gold100", GodotBilling.PRODUCT_TYPE_IN_APP, true,  false)
var product_premium  := billing.create_product("com.example.premium", GodotBilling.PRODUCT_TYPE_SUBS,   false, true )

func _ready() -> void:
	billing.connect("update_products", self, "_on_update_products")
	billing.connect("update_transactions", self, "_on_update_transactions")
	
	billing.request_products()

func purchase_dlc() -> void :
	billing.request_purchase(product_dlc)

func is_purchased_dlc() -> bool :
	return billing.is_purchased(product_dlc)

func _on_update_products() -> void :
	for val in billing.get_products().get_products_valid() :
		var product := val as GodotBillingProduct
		print("\nPRODUCT")
		print("SKU:",          product.sku)
		print("DISPLAY NAME:", product.display_name)
		print("PRICE:",        product.price)
		print("\n")

func _on_update_transactions() -> void :
	for val in billing.get_transaction_purchased() :
		var transaction := val as GodotBillingTransaction
		
		match transaction.product :
			product_dlc :
				print("unlock DLC")
				game.dlc_access = true
				
			product_gold_100 :
				print("give me 100 gold")
				game.gold += 100
				billing.consume_transaction(transaction)
				
			product_premium :
				print("unlock premium status")
				game.premium_access = true
			
			_ :
				print("Unknow product - ", transaction.product)








class SampleGame :
	var premium_access := false
	var dlc_access := false
	var gold := 0
