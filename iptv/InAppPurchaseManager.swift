//
//  InAppPurchaseManager.swift
//  iptv
//
//  Created by Alexandr Kolganov on 07.01.17.
//  Copyright © 2017 Home. All rights reserved.
//

import Foundation
import StoreKit

class InAppProduct {
    
    enum State {
        case noInit, tryPeriod, expire, bought
    }
    
    let id:String
    
    fileprivate var _state: State = .noInit {
        didSet {
            print("set _state \(_state)")
        }
    }
    
    var state: State { //get
        if _state == .tryPeriod {
            checkTryPeriod()
            if _state != .tryPeriod {
                write()
            }
        }
        return _state
    }
    
    
    fileprivate var startTryDate: Date?
    fileprivate var expireTime  = TimeInterval(3*60) // TimeInterval(24*60*60)
    
    var expireTryDate: Date? {
        if startTryDate != nil {
            return startTryDate?.addingTimeInterval(expireTime)
        }
        return nil
    }
    
    var skProduct : SKProduct? {
        didSet {
            print("set skProduct \(skProduct?.price)")
        }
    }
    
    init(_ id:String) {
        print("Init product: \(id)")
        self.id = id
    }
    
    static let dateFormat = "yy.MM.dd hh:mm"
    
    private func stateFromString(_ str: String) {
        if str == "no" {
            _state = .noInit
        }
        else if str == "bought" {
            _state = .bought
        }
        else if str == "expire" {
            _state = .expire
        }
        else {
            startTryDate = str.toFormatDate(InAppProduct.dateFormat)
            if startTryDate != nil {
                _state = .tryPeriod
                checkTryPeriod()
            }
            else {
                _state = .noInit
            }
        }
    }
    
    fileprivate func checkTryPeriod() {
        if startTryDate != nil {
            if startTryDate! > Date() || startTryDate!.addingTimeInterval(expireTime) < Date()  {
                _state = .expire
            }
        }
    }
    
    private func stateToString() -> String {
        
        if _state == .tryPeriod {
            checkTryPeriod()
        }
        
        if _state == .noInit {
            return "no"
        }
        else if _state == .bought {
            return "bought"
        }
        else if _state == .expire {
            return "expire"
        }
        else if _state == .tryPeriod &&  startTryDate != nil {
            return startTryDate!.toFormatString(InAppProduct.dateFormat)
        }
        return "no"
    }
    
    fileprivate func write() {
        UserDefaults.standard.set(stateToString() as? NSString, forKey: "product." + id)
        UserDefaults.standard.synchronize()
    }
    
    fileprivate func read() {
        if let strState = UserDefaults.standard.object(forKey: "product." + id) as? NSString {
            stateFromString(strState as String)
        }
    }
    

    
}


class InAppPurchaseManager :  NSObject, SKProductsRequestDelegate, SKPaymentTransactionObserver {
    
    static let changeStateNotification = "ChangeStateNotification"
    
    static let productPipId = "pip"
    static let productIds = [productPipId]
    
    var currentRequest : SKProductsRequest?
    
    lazy var products : [InAppProduct] = {
        
        var productList = [InAppProduct]()
        for productId in InAppPurchaseManager.productIds {
            var product  = InAppProduct(productId)
            //get _state from UserDefault
            product.read()
            productList.append(product)
        }
        return productList
    }()
    
    var tryTimer : Timer?
    
    // Singleton
    static let instance = InAppPurchaseManager()    
    
    func getProductByIdentifier(_ productIdentifier: String) -> InAppProduct? {
        if let shortId = productIdentifier.components(separatedBy: ".").last {
            return _getProductById(shortId)
        }
        return nil
    }
    
    private func _getProductById(_ id: String) -> InAppProduct? {
        return  products.first(where:{$0.id == id})
    }
    
    class func getProductById(_ id: String) -> InAppProduct? {
        return InAppPurchaseManager.instance._getProductById(id)
    }
    
    func startTryPeriod(_ product: InAppProduct) {
        if product._state == .noInit {
            product._state = .tryPeriod
            product.startTryDate = Date()
            product.write()
            resetTryTimer()
            NotificationCenter.default.post(name: Notification.Name(InAppPurchaseManager.changeStateNotification),
                                            object: product)
        }
    }
    
    
    
    fileprivate func resetTryTimer() {
        if tryTimer != nil {
            tryTimer!.invalidate()
            tryTimer = nil
        }
        
        //get product
        var tryProduct : InAppProduct? = nil
        for product in products {
            if product._state == .tryPeriod {
                product.checkTryPeriod()
                if product._state == .tryPeriod {
                    if tryProduct == nil || tryProduct!.expireTryDate! > product.expireTryDate! {
                        tryProduct = product
                    }
                }
            }
        }
        
        //set timer
        if tryProduct != nil {
            let timeInterval = tryProduct!.expireTryDate!.timeIntervalSinceNow + 0.5
            tryTimer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: false, block: { (_) in
                if tryProduct!._state == .tryPeriod {
                    tryProduct!.checkTryPeriod()
                    NotificationCenter.default.post(name: Notification.Name(InAppPurchaseManager.changeStateNotification),
                                                    object: tryProduct!)
                }
                self.resetTryTimer()
            })
        }
        
    }
    
    func requestProductData()
    {
        let bundleID = Bundle.main.bundleIdentifier!
        var productIdentifiers = Set<String>()
        for productId in InAppPurchaseManager.productIds {
            productIdentifiers.insert(bundleID + "." + productId)
        }
        currentRequest = SKProductsRequest(productIdentifiers:productIdentifiers)
        currentRequest?.delegate = self
        currentRequest?.start()
        
        resetTryTimer()
    }
    
    
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        
        for skProduct in response.products {
            if let product = getProductByIdentifier(skProduct.productIdentifier) {
                product.skProduct = skProduct
            }
            else {
                print("not found product with identifier: \(skProduct.productIdentifier)")
            }
        }
        
        for invalidIdentifier in response.invalidProductIdentifiers {
            print("invalid product identifier: \(invalidIdentifier)")
        }
    }
    
    func buyProduct(_ product: InAppProduct) {
        if let skProduct = product.skProduct {
            let payment = SKPayment(product: skProduct)
            SKPaymentQueue.default().add(payment)
        }
        else {
            print("Not found skproduct property for product: \(product.id)")
        }
    }
    
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        
        
        for transaction in transactions {
            
            let product = getProductByIdentifier(transaction.payment.productIdentifier)
            
            switch transaction.transactionState {
                
            case SKPaymentTransactionState.purchased:
                if product != nil {
                    if product!._state != .bought {
                        product!._state = .bought
                        product!.write()
                        NotificationCenter.default.post(name: Notification.Name(InAppPurchaseManager.changeStateNotification),
                                                        object: product!)
                    }
                }
                SKPaymentQueue.default().finishTransaction(transaction)
                
            case SKPaymentTransactionState.failed:
                SKPaymentQueue.default().finishTransaction(transaction)
            default:
                break
            }
            
        }
    }
    
    func restorePurchases() {
        SKPaymentQueue.default().add(self)
        SKPaymentQueue.default().restoreCompletedTransactions()
    }
    
    func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
        
        for transaction in queue.transactions {
            let product = getProductByIdentifier(transaction.payment.productIdentifier)
            if product != nil {
                if product!._state != .bought {
                    product!._state = .bought
                    product!.write()
                    NotificationCenter.default.post(name: Notification.Name(InAppPurchaseManager.changeStateNotification),
                                                    object: product!)
                }
            }
            else {
                print("not found product with identifier: \(transaction.payment.productIdentifier)")
            }
        }
        
    }
    
}
