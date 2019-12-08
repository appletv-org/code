//
//  UITextExtension.swift
//  tvorg
//
//  Created by alex on 04.11.2019.
//  Copyright © 2019 Home. All rights reserved.
//

import UIKit


extension UITextView {
    override open func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        if (context.nextFocusedView == self) {
            self.backgroundColor = UIColor.white
        }
        else {
            self.backgroundColor = UIColor.clear
        }
    }
    
}
