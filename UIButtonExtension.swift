//
//  UIButtonExtension.swift
//  tvorg
//
//  Created by alex on 04.11.2019.
//  Copyright © 2019 Home. All rights reserved.
//

import UIKit

extension UIButton {
    func setTitleForAllStates(_ title: String) {
        self.setTitle(title, for: .normal)
        self.setTitle(title, for: .focused)
        self.setTitle(title, for: .selected)
    }
    
    func setImageForAllStates(_ image: UIImage) {
        self.setImage(image, for: .normal)
        self.setImage(image, for: .focused)
        self.setImage(image, for: .selected)
    }
}
