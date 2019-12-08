//
//  UIFontExtension.swift
//  tvorg
//
//  Created by alex on 04.11.2019.
//  Copyright © 2019 Home. All rights reserved.
//

import UIKit

extension UIFont {
    
    func withTraits(traits:UIFontDescriptorSymbolicTraits...) -> UIFont {
        if let descriptor = self.fontDescriptor.withSymbolicTraits(UIFontDescriptorSymbolicTraits(traits)) {
            return UIFont(descriptor: descriptor, size: 0)
        }
        return self
    }
    
    func bold() -> UIFont {
        return withTraits(traits: .traitBold)
    }
    
    func italic() -> UIFont {
        return withTraits(traits: .traitItalic)
    }
    
    func boldItalic() -> UIFont {
        return withTraits(traits: .traitBold, .traitItalic)
    }
    
    func regular() -> UIFont {
        let descriptor = self.fontDescriptor.withSymbolicTraits(UIFontDescriptorSymbolicTraits(rawValue: 0))
        return UIFont(descriptor: descriptor!, size: 0)
    }
    
}
