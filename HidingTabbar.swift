//
//  HideTabbar.swift
//  tvorg
//
//  Created by alex on 04.11.2019.
//  Copyright © 2019 Home. All rights reserved.
//

import UIKit

class HidingTabbar: UITabBar
{
    var yShow : CGFloat?;
    
    
    
    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        super.didUpdateFocus(in: context, with: coordinator)
        
        if #available(tvOS 13.0, *) {
            // tvOS 13+
       
            let focusChanged = self.focusedChange(context)
            print(focusChanged)
            
            if(yShow == nil) {
                yShow = self.frame.origin.y;
            }
            
            
            if focusChanged == .focused {
                    UIView.animate(withDuration: 0.3, animations: {
                        var frame = self.frame;
                        frame.origin.y = self.yShow!;
                        self.frame = frame;
                        //self.transform = CGAffineTransform(translationX: 0, y: 0)
                    })
            }

            else if focusChanged == .unFocused {
                UIView.animate(withDuration: 0.3, animations: {
                    // self.transform = CGAffineTransform(translationX: 0, y: -250)
                    var frame = self.frame;
                    frame.origin.y = -self.globalPoint!.y - self.frame.size.height;
                    self.frame = frame;
                })
            }
        } else {
                       // iOS 9 and tvOS 9 older code
        }
    }
        
 
}
