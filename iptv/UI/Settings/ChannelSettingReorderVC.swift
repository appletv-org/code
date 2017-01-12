//
//  ChannelSettingReorderVC.swift
//  iptv
//
//  Created by Alexandr Kolganov on 23.12.16.
//  Copyright © 2016 Home. All rights reserved.
//

import UIKit

class ChannelSettingReorderVC : BottomController {
    
    var name:String = ""
    
    @IBOutlet weak var movedLabel: UILabel!
    @IBOutlet weak var infoLabel: UILabel!
    
    @IBOutlet weak var arrowLeftButton: UIButton!
    @IBOutlet weak var arrowRightButton: UIButton!

    @IBAction func leftAction(_ sender: Any) {
        let _ = ChannelManager.reorderPath(channelSettingVC.currentPath, shift:-1)
        channelSettingVC.reloadPath(channelSettingVC.currentPath, isFocused:false)
        channelSettingVC.channelPickerVC.centerElement(name, animated:true)
    }
    @IBAction func rightAction(_ sender: Any) {
        let _ = ChannelManager.reorderPath(channelSettingVC.currentPath, shift:1)
        channelSettingVC.reloadPath(channelSettingVC.currentPath, isFocused:false)
        channelSettingVC.channelPickerVC.centerElement(name, animated:true)
    }
    
    func refresh() {
        name = ChannelManager.lastName(channelSettingVC.currentPath)
        movedLabel.text = "move \"\(name)\""
    }
    
}
