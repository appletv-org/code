//
//  ChannelSettingHideVC.swift
//  iptv
//
//  Created by Alexandr Kolganov on 23.12.16.
//  Copyright © 2016 Home. All rights reserved.
//

import UIKit

class ChannelSettingHideVC : BottomController, BottomControllerProtocol {
    
    
    @IBOutlet weak var infoLabel: UILabel!
    @IBOutlet weak var hideButton: UIButton!
    
    @IBAction func hideAction(_ sender: Any) {
        let path = channelSettingVC.currentPath
        let parentGroup = ChannelManager.findParentGroup(path)
        var ind = parentGroup!.findDirIndex(path.last!)
        
        var err : Error? = nil
        if channelSettingVC.isHiddenGroup {
            err = ChannelManager.unhidePath(path)
        }
        else {
            err = ChannelManager.delPathElement(path)
        }
        
        if err != nil {
            infoLabel.text = errMsg(err!)
            return
        }

        
        var newPath = channelSettingVC.currentPath
        let _ = newPath.popLast()
        let  count = parentGroup!.countDirElements()
        if count > 0  {
            if ind >= count {
                ind = count-1
            }
            if let newElement = parentGroup!.findDirElement(index: ind) {
                newPath.append(newElement.name)
            }
        }
        
        channelSettingVC.reloadPath(newPath)
    }
    
    
    func refresh() {
        

        var text = ""
        if channelSettingVC.isHiddenGroup {
            text += "Restore "
            hideButton.setTitleForAllStates("Restore")
            
        }
        else {
            text += "Hide "            
            hideButton.setTitleForAllStates("Hide")
        }
       
        
        if case .channel(_) = channelSettingVC.dirElement! {
            text += "channel "
        }
        else {
            text += "group "
        }
        text += "\"\(channelSettingVC.dirElement!.name)\""
        
        infoLabel.text = text
        
    }
    
    
    
}
