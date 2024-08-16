extends Reference
class_name GodotBillingTransaction


#"sku" : transaction.productID,
#"original_id" : "\(transaction.originalID)",
#"purchased_date" : purchaseData,
#"transaction_id" : "\(transaction.id)",
#"product_id" : transaction.productID,
#"bundle_id" : transaction.appBundleID,
#"product_type" : typeProduct,
#"subscription_group" : transaction.subscriptionGroupID ?? "",
#"expiration_date" : expirationDate,
#"is_upgraded" : transaction.isUpgraded ? "yes" : "no",
#"quantity" : "\(transaction.purchasedQuantity)",
#"is_revocation" : transaction.revocationDate != nil ? "yes" : "no",
#"revocation_date" : revocationDate,
#"revocation_reason" : revocationReason,
#"ownership_type" : transaction.ownershipType.rawValue

enum StatusCode {
	Purchased,
	PurchaseDeferred,
	Revocation,
	Refound,
	Canceled,
	Error,
	Unvaliavble,
}


const Product := preload("res://addons/godot_billing_service/product.gd")

var product : Product = null
var transaction_id: String = ""
var status: int = StatusCode.Unvaliavble

var quantity: int = 1
var purchased_date: int = 0

var optional := {}

func _to_string() -> String:
	return "[GodotBillingTransaction: transaction_id:<%s>  id:<%d>  product:%s]" % [transaction_id, get_instance_id(), str(product)]

func get_status_text() -> String :
	for key in StatusCode.keys() :
		if StatusCode[key] == status :
			return key
	
	return ""

func copy_from(transaction) -> void :
	product        = transaction.product
	transaction_id = transaction.transaction_id
	status         = transaction.status
	quantity       = transaction.quantity
	purchased_date = transaction.purchased_date
	optional       = transaction.optional



