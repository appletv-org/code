//
//  InAppPurchaseManager.swift
//  iptv
//
//  Created by Alexandr Kolganov on 07.01.17.
//  Copyright © 2017 Home. All rights reserved.
//

import Foundation
import StoreKit

struct InAppProduct {
    
    enum State {
        case noInit, tryPeriod, expire, bought
    }
    
    let id:String
    var state: State = .noInit
    var startTryDate: Date?
    var expireTime  = TimeInterval(24*60*60)
    
    var skProduct : SKProduct?
    
    init(_ id:String) {
        self.id = id
    }
    
    static let dateFormat = "yy.MM.dd hh:mm"
    
    mutating func stateFromString(_ str: String) {
        if str == "no" {
            state = .noInit
        }
        else if str == "bought" {
            state = .bought
        }
        else if str == "expire" {
            state = .expire
        }
        else {
            startTryDate = str.toFormatDate(InAppProduct.dateFormat)
            if startTryDate != nil {
                state = .tryPeriod
                checkTryPeriod()
            }
            else {
                state = .noInit
            }
        }
    }
    
    mutating func checkTryPeriod() {
        if startTryDate != nil {
            if startTryDate! < Date() || startTryDate!.addingTimeInterval(expireTime) > Date() {
                state = .expire
            }
        }
    }
    
    mutating func stateToString() -> String {
        
        if state == .tryPeriod {
            checkTryPeriod()
        }
        
        if state == .noInit {
            return "no"
        }
        else if state == .bought {
            return "bought"
        }
        else if state == .expire {
            return "expire"
        }
        else if state == .tryPeriod &&  startTryDate != nil {
            return startTryDate!.toFormatString(InAppProduct.dateFormat)
        }
        return "no"
    }
    
    mutating func save() {
        UserDefaults.standard.set(stateToString() as? NSString, forKey: "product." + id)
    }
    
    mutating func read() {
        if let strState = UserDefaults.standard.object(forKey: "product." + id) as? NSString {
            stateFromString(strState as String)
        }
    }
    
}


class InAppPurchaseManager : NSObject, SKProductsRequestDelegate, SKPaymentTransactionObserver {
    
    static let purchaseNotification = "PurchaseNotification"
    
    
    
    static let productPipId = "pip"
    static let productIds = [productPipId]
    
    var currentRequest : SKProductsRequest?
    
    lazy var products : [InAppProduct] = {
        
        var products = [InAppProduct]()
        for productId in InAppPurchaseManager.productIds {
            var product  = InAppProduct(productId)
            //get state from UserDefault
            product.read()
            products.append(product)
        }
        return products
    }()
    
    // Singleton
    static let instance = InAppPurchaseManager()
    
    
    func getProductById(_ productIdentifier: String) -> InAppProduct? {
        let shortId = productIdentifier.components(separatedBy: ".").last!
        if let product = products.first(where:{$0.id == shortId}) {
            return product
        }
        return nil
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
    }
    
    
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        
        for skProduct in response.products {
            if var product = getProductById(skProduct.productIdentifier) {
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
            
            var product = getProductById(transaction.payment.productIdentifier)
            
            switch transaction.transactionState {
                
            case SKPaymentTransactionState.purchased:
                if product != nil {
                    product!.state = .bought
                    product!.save()
                }
                SKPaymentQueue.default().finishTransaction(transaction)
                
            case SKPaymentTransactionState.failed:
                SKPaymentQueue.default().finishTransaction(transaction)
            default:
                break
            }
            let userInfo : [String:Any] = ["id" : transaction.payment.productIdentifier, "result": transaction.transactionState]
            NotificationCenter.default.post(name: Notification.Name(InAppPurchaseManager.purchaseNotification),
                                            object: nil,
                                            userInfo: userInfo )
            
        }
    }
    
    func restorePurchases() {
        SKPaymentQueue.default().add(self)
        SKPaymentQueue.default().restoreCompletedTransactions()
    }
    
    func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
        for transaction in queue.transactions {
            var product = getProductById(transaction.payment.productIdentifier)
            if product != nil {
                product!.state = .bought
                product!.save()
            }
            else {
                print("not found product with identifier: \(transaction.payment.productIdentifier)")
            }
            let userInfo : [String:Any] = ["id" : transaction.payment.productIdentifier, "result": transaction.transactionState]
            NotificationCenter.default.post(name: Notification.Name(InAppPurchaseManager.purchaseNotification),
                                            object: nil,
                                            userInfo: userInfo )
        }
    }
    
}
