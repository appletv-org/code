//
//  PipPaymentVC.swift
//  iptv
//
//  Created by Alexandr Kolganov on 08.01.17.
//  Copyright © 2017 Home. All rights reserved.
//

import UIKit
import StoreKit

class PIPPaymentVC : FocusedViewController {
    
    var pipProduct : InAppProduct?
    

    @IBOutlet weak var containerView: UIView!

    @IBOutlet weak var tryExpireLabel: UILabel!
    @IBOutlet weak var trialButton: UIButton!
    
    @IBOutlet weak var unablePaymentLabel: UILabel!
    @IBOutlet weak var buyButton: UIButton!
    
    
    @IBAction func startTrialAction(_ sender: Any) {
        if  pipProduct != nil
        {
            InAppPurchaseManager.instance.startTryPeriod(pipProduct!)
        }
        
    }
    
    
    @IBAction func buyAction(_ sender: Any) {
        if pipProduct != nil {
            InAppPurchaseManager.instance.buyProduct(pipProduct!)
        }
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func restoreAction(_ sender: Any) {
        InAppPurchaseManager.instance.restorePurchases()
        self.dismiss(animated: true, completion: nil)
    }
    
    
    @IBAction func cancelAction(_ sender: Any) {
        
        self.dismiss(animated: true, completion: nil)
    }
    
    static func loadFromIB() -> PIPPaymentVC {
        let mainStoryboard = UIStoryboard(name: "Channel", bundle: Bundle.main)
        let pipPaymentVC = mainStoryboard.instantiateViewController(withIdentifier: "PIPPaymentVC") as! PIPPaymentVC
        return pipPaymentVC
    }
    
    override func viewDidLoad() {
        
        containerView.layer.cornerRadius = 20
        
        
        pipProduct = InAppPurchaseManager.getProductById(InAppPurchaseManager.productPipId)
        
        if  pipProduct != nil,
            let skProduct = pipProduct!.skProduct
        {
            //trial
            if pipProduct!.state == .noInit {
                tryExpireLabel.isHidden = true
                trialButton.isHidden = false
            }
            else {
                tryExpireLabel.isHidden = false
                trialButton.isHidden = true
            }
            
            //buy
            if SKPaymentQueue.canMakePayments() {
                
                unablePaymentLabel.isHidden = true
                buyButton.isHidden = false
                
                let numberFormatter = NumberFormatter()
                numberFormatter.formatterBehavior = .behavior10_4
                numberFormatter.numberStyle = .currency
                numberFormatter.locale = skProduct.priceLocale
                if let formattedPrice = numberFormatter.string(from: skProduct.price) {
                    buyButton.setTitleForAllStates("Buy for \(formattedPrice)")
                }
            }
            else {
                unablePaymentLabel.isHidden = false
                buyButton.isHidden = true
            }
        }
        
    }
    
}
