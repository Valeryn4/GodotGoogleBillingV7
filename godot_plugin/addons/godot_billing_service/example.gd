extends Node




#Примеры создания продуктов
#   При создании продукта, ему необхоодимо задать уникальный индетификатор.
# желательно созданный продукт добавить в биллинг систему как можно скорее.
#   Если в билинге будет два продукта с одинаковым ID, актуальным останется старый продукт, 
# который скопирует в себя все параметры нового продукта. По этому не создавайте два одинаковых
# продукта с одинаковыми ID.
#создаем продукт с заданным SKU в биллинг системе. Продукт сразу попадает в список 
#данный способ гарантирует, что не будут созданы лишние копии продукта с заданным ID
#если продукт с заданным ID уже создан, он вернет его экземпляр
var example_billing := GodotBilling.new()
var product_create_now := example_billing.create_product("com.example.sku")

#статический метод. Создаем продукт с заданным SKU вне биллинга.
var product_create_deferred := GodotBilling.create_product_without_billing("com.example.sku")
#создание продукта в ручную.
var product_create_custom := GodotBillingProduct.new()

#######################################

# Пример работы биллинг системы

#создаем биллинг (можно в виде синглтона)
var billing := GodotBilling.new()

#    Тут заданы переменные для продуктов, которые будут инициированы позже
#подписки
var product_subs_month: GodotBillingProduct = null
var product_subs_year: GodotBillingProduct = null

#перманентный продукт
var product_dlc: GodotBillingProduct = null

#расходуемый продукт
var product_100_golds: GodotBillingProduct = null

func _ready() -> void:
	
	#инициализируем продукты, в зависимости от целевой платформы
	
	if OS.get_name() == "Android" : #создаем продукты для андройд платформы
		product_subs_month = billing.create_product("com.example.android.subs.month")
		product_subs_year  = billing.create_product("com.example.android.subs.year")
		product_dlc        = billing.create_product("com.example.android.noncons.dlc")
		product_100_golds  = billing.create_product("com.example.android.cons.gold100")
	elif OS.get_name() in ["iOS", "OSX", "MacOS", "tvOS"] : #создаем продукты для apple проекта
		product_subs_month = billing.create_product("com.example.apple.subs.month")
		product_subs_year  = billing.create_product("com.example.apple.subs.year")
		product_dlc        = billing.create_product("com.example.apple.noncons.dlc")
		product_100_golds  = billing.create_product("com.example.apple.cons.gold100")
	
	######### НАСТРОЙКА ПРОДУКТА #############
	
	#задаем тип продукта.
	product_subs_month.product_type = GodotBilling.PRODUCT_TYPE_SUBS
	product_subs_year.product_type  = GodotBilling.PRODUCT_TYPE_SUBS
	product_dlc.product_type        = GodotBilling.PRODUCT_TYPE_IN_APP
	product_100_golds.product_type  = GodotBilling.PRODUCT_TYPE_IN_APP
	#указываем, что данный продукт считается расходуемый. по умолчанию - false
	product_100_golds.is_consumable = true
	
	#данные параметры надо явно указывать для google billing. 
	#для ios данная операция не обязательна, т.к. ios предоставляет эту информацию автоматически
	#альтернативный способ:
	billing.create_product(
		"com.example.apple.cons.gold200", #sku 
		GodotBilling.PRODUCT_TYPE_IN_APP, #type product #тип 
		true,  #is consumable #расходуемый?
		false #is renewable   #возобновляемый?
		)
	
	######### ЗАПРОС ИНФОРМАЦИИ ОБ ПРОДУКТЕ ######
	
	#данная функция запрашивает информацию об продуктах из billing системы.
	billing.request_products() 
	#данная функция запрашивает информацию только об указанных продуктах
	billing.request_products_from_list([product_subs_month, product_subs_year])
	
	#данная операция необходима, что бы получить ту или иную информацию об продуктах
	#такую как цены, периуд подписки, тип продукта, описание и т.д.
	#можно не запрашивать эту информацию и полность настроить продукт самостоятельно. 
	####################################
	
	######## ПОКУПКА ПРОДУКТА ##########
	
	#покупка продукта
	billing.request_purchase(product_dlc)
	#восстановить покупку (обновляет информацию об транзакциях)
	billing.restore_purchase()
	######################################
	
	########## ПРОДУКТы ############
	
	#get_products() - вернет контейнер с продуктами
	var products := billing.get_products() 
	#вернет продукт по его SKU или null
	var example_product := products.get_product_from_sku("com.example.sku")
	#вернет валидный список продуктов, которые были подтверждены билинговой системой
	var validate_products_list := products.get_products_valid()
	
	print("PRODUCT INFO!")
	print("TITLE:       ", example_product.display_name)
	print("DESCRIPTION: ", example_product.description)
	print("PRICE:       ", example_product.price)
	########################################
	
	######### ТРАНЗАКЦИИ ##################
	
	#get_transactions() - вернет контейнер с транзакциями
	var transactions := billing.get_transactions()
	#вернет список не отсортированных транзакций
	var example_transactions := transactions.get_transactions()
	#вернет список транзакций с подтвержденной покупкой
	var example_purchased_transactions := transactions.get_transactions_purchased()
	
	for val in example_transactions :
		var transaction := val as GodotBillingTransaction
		if transaction :
			var product := transaction.product #каждая транзакция привязана к продукту
			if product == example_product : print("is example product!!!")
			
			var status  := transaction.status #у каждой транзакции есть ее состояние 
			if status == GodotBilling.STATUS_PURCHASED : print("OK")
			
			var unix_date := transaction.purchased_date #у каждой транзакции есть дата покупки в unix time
			var quantity  := transaction.quantity #у каждой транзакции есть количество товара, если это предусмотрено товаром
	
	####################################################


#### ПРИМЕР ПОКУПКИ
func example_purchase() -> void :
	#что бы отследить успешность покупки, достаточно подписаться на сигнал
	#данный сигнал срабатывает только при покупке, а не восстановлении товара!!!
	billing.connect("purchase_success", self, "_on_example_purchase_success")
	billing.request_purchase(product_dlc)

func _on_example_purchase_success(transaction: GodotBillingTransaction) -> void :
		if transaction.product == product_dlc :
			print("UNLOCK DLC")

#### ПРИМЕР РАБОТЫ С ТРАНЗАКЦИЯМИ

func example_restore() -> void :
	#подписываемся на обновление конкретной транзакции
	billing.connect("update_transaction", self, "_on_example_update_transaction") 
	#подписываемся любое обновление всего списка транзакций
	billing.connect("update_transactions", self, "_on_example_update_transactions")
	#запрашиваем существующие транзакции путем их восстановления
	billing.restore_purchase()

#работа с одной обновленной транзакцией
func _on_example_update_transaction(transaction: GodotBillingTransaction) -> void :
	match transaction.status :
		GodotBilling.STATUS_PURCHASED : #если куплено
			match transaction.product :
				product_dlc :
					print("Unlock DLC")
				product_100_golds :
					print("Give 100 golds")
					billing.consume_transaction(transaction) #употребляем расходуемый товар
		GodotBilling.STATUS_REFOUND : #если сделали рефанд
			if transaction.product == product_dlc :
				print("Locked DLC")

func _on_example_update_transactions() -> void :
	pass 

func example_check_transactions() -> void :
	var transactions := billing.get_transactions()
	for transaction in transactions.get_transactions() : #перебираем все существующие транзакции
		match transaction.status :
			GodotBilling.STATUS_PURCHASED : #если куплено
				match transaction.product :
					product_dlc :
						print("Unlock DLC")
					product_100_golds :
						print("Give 100 golds")
						billing.consume_transaction(transaction) #употребляем расходуемый товар
			GodotBilling.STATUS_REFOUND : #если сделали рефанд
				if transaction.product == product_dlc :
					print("Locked DLC")

###############################################################################
#### БЫСТРЫЙ СТАРТ ######
