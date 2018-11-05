//
//  Analytics.swift
//  iptv
//
//  Created by Alexandr Kolganov on 12.01.17.
//  Copyright © 2017 Home. All rights reserved.
//

import Foundation
import Flurry_iOS_SDK

class Analytics {

    lazy var deviceMD5 : String?  = {
        if let uiDevice = UIDevice.current.identifierForVendor?.uuidString {
            return md5(uiDevice)
        }
        return nil
        
    }()

    // Singleton
    static let instance = Analytics()
    private init() {}
    
    
    class func start() {
        #if DEBUG
            Flurry.startSession("8SDBFXS2X8VM9ZPMDK5Y")
        #else
            Flurry.startSession("XF4BQRWNKNRTQQ64B3CK")
        #endif
    }


    
    
    
    class func log(_ eventName:String, params:[String:String]) {
        Flurry.logEvent(eventName, withParameters:params)
    }
    
    class func logDevice(_ eventName:String, params:[String:String]) {
        var newparams = params
        if let deviceMD5 = Analytics.instance.deviceMD5 {
            newparams["device"] = deviceMD5
        }
        else {
            newparams["device"] = "undefine"
        }
        Analytics.log(eventName, params: newparams)
    }
    
    class func logCountry(_ eventName:String, params:[String:String]) {
        var newparams = params
        let locale = Locale.current.identifier
        newparams["locale"] = locale
        Analytics.log(eventName, params: newparams)
    }
}
