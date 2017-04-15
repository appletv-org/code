//
//  OtherSettings.swift
//  tvorg
//
//  Created by Alexandr Kolganov on 15.04.17.
//  Copyright © 2017 Home. All rights reserved.
//

import UIKit


class OtherSettings : FocusedViewController {
    
    static let useVLC = "useVLC"
    
    static var preferVLC : Bool = {
        return UserDefaults.standard.bool(forKey: OtherSettings.useVLC)
    }()

    
    
    @IBOutlet weak var preferPlayer: UISegmentedControl!
    
    @IBAction func changePreferPlayer(_ sender: UISegmentedControl) {
        let newValue = (sender.selectedSegmentIndex == 1)
        if(newValue != OtherSettings.preferVLC) {
            OtherSettings.preferVLC = newValue
            UserDefaults.standard.set(newValue, forKey: OtherSettings.useVLC)
        }
    }
    
    override func viewDidLoad() {
            
        addNavigationTitle("Other settings")
        
        preferPlayer.selectedSegmentIndex = OtherSettings.preferVLC ? 1 : 0
    }

    
}

