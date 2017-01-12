//
//  ChannelSettingDeleteVC.swift
//  iptv
//
//  Created by Alexandr Kolganov on 23.12.16.
//  Copyright © 2016 Home. All rights reserved.
//

import UIKit

class ChannelSettingDeleteVC : BottomController, BottomControllerProtocol {
    
    
    @IBOutlet weak var infoLabel: UILabel!
    @IBOutlet weak var deleteButton: UIButton!
    
    @IBAction func deleteAction(_ sender: Any) {
        confirmStack.isHidden = false
        self.viewToFocus = yesButton
    }
    @IBOutlet weak var confirmStack: UIStackView!
 
    @IBOutlet weak var yesButton: UIButton!
    
    @IBAction func yesAction(_ sender: Any) {
        confirmStack.isHidden = true
        
        let prevPath = channelSettingVC.nextPath()
        let err = ChannelManager.delPathElement(channelSettingVC.currentPath)
        
        if err != nil {
            infoLabel.text = errMsg(err!)
            return
        }
        
        channelSettingVC.reloadPath(prevPath)
    }
    
    @IBAction func noAction(_ sender: Any) {
        confirmStack.isHidden = true
    }
    
    func refresh() {
        confirmStack.isHidden = true
        deleteButton.isEnabled = channelSettingVC.isFocusedPath
        
        var text = ""
        
        if channelSettingVC.isFocusedPath {
       
            text += "Delete"
                
            if case .channel(_) = channelSettingVC.dirElement! {
                text += " channel"
            }
            else {
                text += " group"
            }
            
            text += ": \"\(channelSettingVC.dirElement!.name)\""            
        }
        else {
            text = "Please,select element"
        }
        infoLabel.text = text
    }
    
}
