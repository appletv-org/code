//
//  FocusedView.swift
//  iptv
//
//  Created by Александр Колганов on 29.09.16.
//  Copyright © 2016 Home. All rights reserved.
//

import UIKit


class FocusedView : UIView {
    
    var focusedObject : UIFocusEnvironment? = nil
    var focusedFunc : (() -> [UIFocusEnvironment]?)? = nil
    var canFocused = true
    
    override var canBecomeFocused : Bool {
        get {
            return canFocused
        }
    }
    
    
    
    override var preferredFocusEnvironments: [UIFocusEnvironment] {
        get {
            if focusedObject != nil {
                return [focusedObject!]
            }
            if focusedFunc != nil {
                if let ret = focusedFunc!() {
                    return ret
                }
            }
            return []            
        }
    }
}
