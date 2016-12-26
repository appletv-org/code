//
//  ChannelSettingInfoVC.swift
//  iptv
//
//  Created by Alexandr Kolganov on 23.12.16.
//  Copyright © 2016 Home. All rights reserved.
//

import UIKit

class ChannelSettingInfoVC : FocusedViewController {
    
    @IBOutlet weak var infoLabel: UILabel!
 
    func setParameters(_ infoText:String) {
        infoLabel.text = infoText
    }
    
    
    
}
