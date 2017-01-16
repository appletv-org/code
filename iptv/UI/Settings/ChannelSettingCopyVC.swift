//
//  ChannelSettingCopyVC.swift
//  iptv
//
//  Created by Alexandr Kolganov on 23.12.16.
//  Copyright © 2016 Home. All rights reserved.
//

import UIKit

class ChannelSettingCopyVC : BottomController {
    
    weak var channelPickerToVC : ChannelPickerVC!
    var toPath = [String]()
    
    
    @IBOutlet weak var channelPickerToView: UIView!
    @IBOutlet weak var infoLabel: UILabel!
    @IBOutlet weak var errorLabel: UILabel!
    
    @IBOutlet weak var moveButton: UIButton!
    @IBOutlet weak var copyButton: UIButton!
    
    @IBAction func moveAction(_ sender: Any) {
    
        let prevPath = channelSettingVC.nextPath()
        
        
        let err = ChannelManager.movePath(channelSettingVC.currentPath, to: toPath)
        if(err == nil) {
            //channelSettingVC.reloadPath(<#T##path: [String]##[String]#>)
            var path = toPath
            path.append(channelSettingVC.currentPath.last!)
            channelPickerToVC.setupPath(path)
            
            channelSettingVC.reloadPath(prevPath)
            

        }
        else {
            errorLabel.text = errMsg(err!)
        }
        
        
    }
    
    @IBAction func copyAction(_ sender: Any) {
        let err = ChannelManager.copyPath(channelSettingVC.currentPath, to: toPath)
        if(err == nil) {
            var path = toPath
            path.append(channelSettingVC.currentPath.last!)
            channelPickerToVC.setupPath(path)
        }
        else {
            errorLabel.text = errMsg(err!)
        }
        
    }
    
    
    
    override func viewDidLoad() {
        
        channelPickerToVC = ChannelPickerVC.insertToView(parentController: self, parentView: channelPickerToView)
        channelPickerToVC.delegate = self
        //channelPickerToVC.setupPath([])
    }
    
    
    func refresh() {
        
        
        moveButton.isEnabled = channelSettingVC.remoteGroup == nil
        
        let infoText = "\"\(ChannelManager.lastName(channelSettingVC.currentPath))\" to \"\(ChannelManager.lastName(toPath))\""
        infoLabel.text = infoText
        errorLabel.text = ""
    }
    
}


extension ChannelSettingCopyVC : ChannelPickerDelegate {

    func changePath(chooseControl: ChannelPickerVC,  path:[String]) {
        print("ChannelSettingsVC.changePath \(path.joined(separator:"->"))")
        
        toPath = path
        refresh()
        
        //var remoteGroup = ChannelManager.findParentRemoteGroup(path)
        
    }

}

