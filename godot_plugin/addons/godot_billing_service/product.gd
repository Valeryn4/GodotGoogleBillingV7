extends Reference
class_name GodotBillingProduct

#"display_name" : product.displayName,
#"description" : product.description,
#"display_price" : product.displayPrice,
#"price" : String(format: "%.5f", price.floatValue) ,
#"sku" : product.id,
#"type_raw": product.type.rawValue,
#"type" : typeProduct,
#"is_family" : product.isFamilyShareable ? "yes" : "no",
#
#"json" : String(data: product.jsonRepresentation, encoding: String.Encoding.utf8) ?? ""

#case .nonConsumable :
#    typeProduct = "non_consumable"
#case .autoRenewable :
#    typeProduct = "auto_renewable"
#case .consumable :
#    typeProduct = "consumable"
#case .nonRenewable :
#    typeProduct = "non_renewable"


signal updated()

enum ProductType { 
	INVALID = 0,
	InApp = 1, 
	Subs = 2,
}

var sku: String = ""

var texture_icon:  Texture = null
var display_name:  String = ""
var description:   String = ""
var display_price: String = ""
var price:         float  = 0.0
var currency:      String = ""
var currency_code: String = ""

var product_type:  int    = ProductType.INVALID
var is_valid:      bool   = false
var is_renewable:  bool   = false
var is_consumable: bool   = false

var optional: Dictionary  = {}


func _to_string() -> String:
	return "[GodotBillingProduct: sku:<%s> id:<%d>]" % [sku, get_instance_id()]

func _init(sku_ : String = "", type: int = ProductType.INVALID, consumable := false, renewable := false) -> void:
	sku = sku_
	product_type = type
	is_consumable = consumable
	is_renewable = renewable


func copy_from(product) -> void :
	sku           = product.sku
	texture_icon  = product.texture_icon
	display_name  = product.display_name
	description   = product.description
	display_price = product.display_price
	price         = product.price
	currency      = product.currency
	currency_code = product.currency_code
	product_type  = product.product_type
	is_valid      = product.is_valid
	is_renewable  = product.is_renewable
	is_consumable = product.is_consumable
	optional      = product.optional
	
	emit_signal("updated")


