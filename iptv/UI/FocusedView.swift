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
    var focusedFunc : (() -> [UIFocusEnvironment]?)?
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
    
    /*
    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        super.didUpdateFocus(in: context, with: coordinator)
        
        if context.nextFocusedView == self {
            self.layer.borderWidth = 3
            self.layer.borderColor = UIColor.blue.cgColor
        }
        else {
            self.layer.borderWidth = 0
        }
    }
    */
}

//focused first focused subview if not define focusedObject or focusedFunc
class ContainerFocused : FocusedView {
    
    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        super.didUpdateFocus(in: context, with: coordinator)
        
        if let nextView = context.nextFocusedView {
            if !(nextView.isDescendant(of: self))  {
                canFocused = true
            }
            else {
                canFocused = false
            }
        }
    }
    
    override var preferredFocusEnvironments: [UIFocusEnvironment] {
        var ret = super.preferredFocusEnvironments
        
        if(ret.count == 0) {
            //find first focused element
            if let subview = self.findFirstInDeep(where: {$0.canBecomeFocused}) {
                ret = [subview]
            }
        }
        return ret
    }
}



