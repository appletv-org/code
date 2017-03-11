//
//  StyleManager.swift
//  iptv
//
//  Created by Alexandr Kolganov on 27.11.16.
//  Copyright © 2016 Home. All rights reserved.
//

import UIKit


class ControllerView : UIView {
    
}

class PanelView : UIView {
    
}




struct Style {
    
    static var current :Style?
    
    //main settings
    var windowBgColor: UIColor?
    
    //focused elements
    var controlBgColor: UIColor?
    var controlTintColor: UIColor?
    var disableTintColor: UIColor?
    
    var focusedBgColor: UIColor?
    var focusedTintColor : UIColor?
    
    var selectedBgColor : UIColor?
    var selectedTintColor: UIColor?
    
    var labelColor: UIColor?
    
    //panel control
    var panelBgColor : UIColor?
    var panelFocusedBgColor : UIColor?
    var panelTextColor : UIColor?
    var panelSelectedColor : UIColor?

    
    
    static func makeStyleDefault() -> Style {
        var style = Style()
        
        style.windowBgColor = UIColor.lightGray
        
        
        style.controlBgColor = UIColor(white: 0.85, alpha: 1.0)
        style.controlTintColor = UIColor.black
        style.disableTintColor = UIColor.darkGray
        
        style.focusedBgColor = UIColor.white
        style.focusedTintColor = UIColor.black
        //style.elementBackgroungColor = UIColor.
        
        
        style.panelBgColor = UIColor.lightGray.withAlphaComponent(0.8)
        style.panelFocusedBgColor = UIColor.darkGray.withAlphaComponent(0.8)
        style.panelTextColor = UIColor(white: 0.1, alpha: 1.0)
        style.panelSelectedColor = UIColor.white
        
        return style
    }
    
}




class StyleManager {
    
    var styles = ["default": Style.makeStyleDefault()]
    
    
    static let instance = StyleManager()
    private init() {
    }
    
    class func applyStyle(_ styleName:String) {
        guard let style = instance.styles[styleName]
        else {
            return
        }
        
        Style.current = style
        
        if style.windowBgColor != nil {
            ControllerView.appearance().backgroundColor = style.windowBgColor
        }
        if style.panelBgColor != nil {
            PanelView.appearance().backgroundColor = style.panelBgColor
        }

    }


}
