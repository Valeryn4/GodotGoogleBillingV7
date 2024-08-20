package com.dtho47.godot.billing

import android.util.Log
import com.limurse.iap.BillingClientConnectionListener
import com.limurse.iap.BillingClientGetCountryListener
import org.godotengine.godot.Godot
import org.godotengine.godot.plugin.GodotPlugin
import org.godotengine.godot.plugin.SignalInfo
import org.godotengine.godot.plugin.UsedByGodot
import org.godotengine.godot.Dictionary

import com.limurse.iap.DataWrappers
import com.limurse.iap.IapConnector
import com.limurse.iap.PurchaseServiceListener
import com.limurse.iap.SubscriptionServiceListener



class GodotGoogleBilling(godot: Godot) : GodotPlugin(godot) {
    private val tag: String = "GodotGoogleBilling"



/*

    const val TYPE_IN_APP = 0
    const val TYPE_SUBS = 3
    signal prices_in_app_update(info: Dictionary)
    {
        sku : String,
        type_product : Int,
        title: String,
        description: String,
        price: String,
        price_amount: Float,
        currency_code: String,
        billing_cycle_count: Int,
        billing_period: String,
        recurrence_mode: Int,
    }


    signal product_purchased(transaction: Dictionary)
    {
        sku: String,
        type_product: Int,
        is_acknowledged: Boolean,
        is_auto_renewing: Boolean,
        purchase_state: Int,
        purchase_token: String,
        signature: String,
        package_name: String,
        response_code: Int, #OK
    }

    signal product_restored(transaction: Dictionary)
    {
        sku: String,
        type_product: Int,
        is_acknowledged: Boolean,
        is_auto_renewing: Boolean,
        purchase_state: Int,
        purchase_token: String,
        signature: String,
        package_name: String,
        response_code: Int, #OK
    }

    signal product_failed(transaction: Dictionary)
    {
        sku: String,
        type_product: Int,
        is_acknowledged: Boolean,
        is_auto_renewing: Boolean,
        purchase_state: Int,
        purchase_token: String,
        signature: String,
        package_name: String,
        response_code: Int, #ERR
    }

    func build(non_consumables_list: Array, consumables_list: Array, subs_list: Array, license_key: String)
    func purchase(sku: String)
    func subscribe(sku: String)
    func unsubscribe(sku: String)

    */


    private val signalPricesUpdate: SignalInfo = SignalInfo("prices_in_app_update", Object::class.java)
    private val signalProductPurchased: SignalInfo = SignalInfo("product_purchased", Object::class.java)
    private val signalProductRestored: SignalInfo = SignalInfo("product_restored", Object::class.java)
    private val signalProductFailed: SignalInfo = SignalInfo("product_failed", Object::class.java)
    private val signalCountryCodeUpdate: SignalInfo = SignalInfo("country_code_update", String::class.java)

    private lateinit var iapConnector: IapConnector
    private var countryCode: String = "US"
    companion object {
        const val TYPE_IN_APP = 0
        const val TYPE_SUBS = 3

        const val ERR_OK = 0

    }
    override fun getPluginName(): String {
        return tag
    }

    override fun getPluginSignals(): Set<SignalInfo> {
        return setOf(
            signalPricesUpdate,
            signalProductPurchased,
            signalProductRestored,
            signalProductFailed,
            signalCountryCodeUpdate
        )
    }


    @UsedByGodot
    fun get_country() : String {

        iapConnector.getCountryCode(object : BillingClientGetCountryListener {
            override fun onResult(countryCode: String) {
                this@GodotGoogleBilling.countryCode = countryCode
                emitSignal(godot, tag, signalCountryCodeUpdate, countryCode)
            }
        })

        return countryCode
    }
    @UsedByGodot
    fun build(nonConsumablesList: Array<String>, consumablesList: Array<String>, subsList: Array<String>, licenseKey: String) {

        Log.i(tag, "build from sku nonConsumablesList: ${nonConsumablesList.toList()}")
        Log.i(tag, "build from sku consumablesList: ${consumablesList.toList()}")
        Log.i(tag, "build from sku subsList: ${subsList.toList()}")

        iapConnector = IapConnector(
            context = godot.requireActivity(), // activity / context
            nonConsumableKeys = nonConsumablesList.toList(), // pass the list of non-consumables
            consumableKeys = consumablesList.toList(), // pass the list of consumables
            subscriptionKeys = subsList.toList(), // pass the list of subscriptions
            key = licenseKey.ifEmpty { null }, // pass your app's license key
            enableLogging = true // to enable / disable logging
        )


        iapConnector.addBillingClientConnectionListener(object  : BillingClientConnectionListener {
            override fun onConnected(status: Boolean, billingResponseCode: Int) {
                Log.i(tag, " billing connected - $status. Code - $billingResponseCode")
                if (status) {
                    get_country()
                }
            }
        })

        iapConnector.addPurchaseListener(object : PurchaseServiceListener {
            override fun onPricesUpdated(iapKeyPrices: Map<String, List<DataWrappers.ProductDetails>>) {
                // list of available products will be received here, so you can update UI with prices if needed

                for (pair in iapKeyPrices)
                {
                    for (details in pair.value)
                    {
                        val dict = Dictionary()


                        dict["sku"] = pair.key
                        dict["type_product"] = TYPE_IN_APP
                        dict["title"] = details.title
                        dict["details"] = details.description
                        dict["price"] = details.price
                        dict["price_amount"] = details.priceAmount
                        dict["currency_code"] = details.priceCurrencyCode
                        dict["billing_cycle_count"] = details.billingCycleCount
                        dict["billing_period"] = details.billingPeriod
                        dict["recurrence_mode"] = details.recurrenceMode

                        emitSignal(godot, tag, signalPricesUpdate, dict)
                    }
                }

            }

            override fun onProductPurchased(purchaseInfo: DataWrappers.PurchaseInfo) {
                // will be triggered whenever purchase succeeded

                val dict = Dictionary()

                dict["sku"] = purchaseInfo.sku
                dict["type_product"] = TYPE_IN_APP
                dict["is_acknowledged"] = purchaseInfo.isAcknowledged
                dict["is_auto_renewing"] = purchaseInfo.isAutoRenewing
                dict["purchase_state"] = purchaseInfo.purchaseState
                dict["purchase_token"] = purchaseInfo.purchaseToken
                dict["signature"] = purchaseInfo.signature
                dict["package_name"] = purchaseInfo.packageName
                dict["response_code"] = ERR_OK
                dict["order_id"] = purchaseInfo.orderId
                dict["json"] = purchaseInfo.originalJson


                emitSignal(godot, tag, signalProductPurchased, dict)
            }

            override fun onProductRestored(purchaseInfo: DataWrappers.PurchaseInfo) {
                // will be triggered fetching owned products using IapConnector

                val dict = Dictionary()

                dict["sku"] = purchaseInfo.sku
                dict["type_product"] = TYPE_IN_APP
                dict["is_acknowledged"] = purchaseInfo.isAcknowledged
                dict["is_auto_renewing"] = purchaseInfo.isAutoRenewing
                dict["purchase_state"] = purchaseInfo.purchaseState
                dict["purchase_token"] = purchaseInfo.purchaseToken
                dict["signature"] = purchaseInfo.signature
                dict["package_name"] = purchaseInfo.packageName
                dict["response_code"] = ERR_OK
                dict["order_id"] = purchaseInfo.orderId
                dict["json"] = purchaseInfo.originalJson


                emitSignal(godot, tag, signalProductRestored, dict)
            }

            override fun onPurchaseFailed(
                purchaseInfo: DataWrappers.PurchaseInfo?,
                billingResponseCode: Int?
            ) {
                if (purchaseInfo != null) {
                    var code: Int = -1
                    if (billingResponseCode != null) {
                        code = billingResponseCode
                    }

                    val dict = Dictionary()

                    dict["sku"] = purchaseInfo.sku
                    dict["type_product"] = TYPE_IN_APP
                    dict["is_acknowledged"] = purchaseInfo.isAcknowledged
                    dict["is_auto_renewing"] = purchaseInfo.isAutoRenewing
                    dict["purchase_state"] = purchaseInfo.purchaseState
                    dict["purchase_token"] = purchaseInfo.purchaseToken
                    dict["signature"] = purchaseInfo.signature
                    dict["package_name"] = purchaseInfo.packageName
                    dict["response_code"] = code
                    dict["order_id"] = purchaseInfo.orderId
                    dict["json"] = purchaseInfo.originalJson

                    emitSignal(godot, tag, signalProductFailed, dict)
                }
            }
        })

        iapConnector.addSubscriptionListener(object : SubscriptionServiceListener {
            override fun onSubscriptionRestored(purchaseInfo: DataWrappers.PurchaseInfo) {
                val dict = Dictionary()

                dict["sku"] = purchaseInfo.sku
                dict["type_product"] = TYPE_SUBS
                dict["is_acknowledged"] = purchaseInfo.isAcknowledged
                dict["is_auto_renewing"] = purchaseInfo.isAutoRenewing
                dict["purchase_state"] = purchaseInfo.purchaseState
                dict["purchase_token"] = purchaseInfo.purchaseToken
                dict["signature"] = purchaseInfo.signature
                dict["package_name"] = purchaseInfo.packageName
                dict["response_code"] = ERR_OK
                dict["order_id"] = purchaseInfo.orderId
                dict["json"] = purchaseInfo.originalJson


                emitSignal(godot, tag, signalProductRestored, dict)
            }

            override fun onSubscriptionPurchased(purchaseInfo: DataWrappers.PurchaseInfo) {
                // will be triggered whenever subscription succeeded
                val dict = Dictionary()

                dict["sku"] = purchaseInfo.sku
                dict["type_product"] = TYPE_SUBS
                dict["is_acknowledged"] = purchaseInfo.isAcknowledged
                dict["is_auto_renewing"] = purchaseInfo.isAutoRenewing
                dict["purchase_state"] = purchaseInfo.purchaseState
                dict["purchase_token"] = purchaseInfo.purchaseToken
                dict["signature"] = purchaseInfo.signature
                dict["package_name"] = purchaseInfo.packageName
                dict["response_code"] = ERR_OK
                dict["order_id"] = purchaseInfo.orderId
                dict["json"] = purchaseInfo.originalJson


                emitSignal(godot, tag, signalProductPurchased, dict)
            }

            override fun onPricesUpdated(iapKeyPrices: Map<String, List<DataWrappers.ProductDetails>>) {
                // list of available products will be received here, so you can update UI with prices if needed
                for (pair in iapKeyPrices)
                {
                    for (details in pair.value)
                    {
                        val dict = Dictionary()


                        dict["sku"] = pair.key
                        dict["type_product"] = TYPE_SUBS
                        dict["title"] = details.title
                        dict["details"] = details.description
                        dict["price"] = details.price
                        dict["price_amount"] = details.priceAmount
                        dict["currency_code"] = details.priceCurrencyCode
                        dict["billing_cycle_count"] = details.billingCycleCount
                        dict["billing_period"] = details.billingPeriod
                        dict["recurrence_mode"] = details.recurrenceMode


                        emitSignal(godot, tag, signalPricesUpdate, dict)
                    }
                }
            }

            override fun onPurchaseFailed(
                purchaseInfo: DataWrappers.PurchaseInfo?,
                billingResponseCode: Int?
            ) {
                if (purchaseInfo != null) {
                    var code: Int = -1
                    if (billingResponseCode != null) {
                        code = billingResponseCode
                    }
                    val dict = Dictionary()

                    dict["sku"] = purchaseInfo.sku
                    dict["type_product"] = TYPE_SUBS
                    dict["is_acknowledged"] = purchaseInfo.isAcknowledged
                    dict["is_auto_renewing"] = purchaseInfo.isAutoRenewing
                    dict["purchase_state"] = purchaseInfo.purchaseState
                    dict["purchase_token"] = purchaseInfo.purchaseToken
                    dict["signature"] = purchaseInfo.signature
                    dict["package_name"] = purchaseInfo.packageName
                    dict["response_code"] = code
                    dict["order_id"] = purchaseInfo.orderId
                    dict["json"] = purchaseInfo.originalJson

                    emitSignal(godot, tag, signalProductFailed, dict)
                }
            }
        })

    }

    @UsedByGodot
    fun purchase(sku: String) {
        iapConnector.purchase(godot.requireActivity(), sku)
    }

    @UsedByGodot
    fun subscribe(sku: String) {
        iapConnector.subscribe(godot.requireActivity(), sku)
    }

    @UsedByGodot
    fun unsubscribe(sku: String) {
        iapConnector.unsubscribe(godot.requireActivity(), sku)
    }


    //GODOT



}
