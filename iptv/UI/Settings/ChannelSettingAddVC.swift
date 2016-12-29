//
//  ChannelSettingAddVC.swift
//  iptv
//
//  Created by Alexandr Kolganov on 20.12.16.
//  Copyright © 2016 Home. All rights reserved.
//

import UIKit

class ChannelSettingAddVC : BottomController, BottomControllerProtocol {
    
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var addButtonsStack: UIStackView!
    @IBOutlet weak var addRemoteGroupButton: UIButton!
    @IBOutlet weak var addEmptyGroupButton: UIButton!
    @IBOutlet weak var addChannelButton: UIButton!
    
    @IBOutlet weak var infoLabel: UILabel!
    
    @IBAction func addRemoteGroupAction(_ sender: Any) {
        setEditController(mode:ChannelSettingEditVC.EditMode.addRemoteGroup)
    }

    @IBAction func addNewGroupAction(_ sender: Any) {
        setEditController(mode:ChannelSettingEditVC.EditMode.addGroup)

    }
    
    @IBAction func addChannelAction(_ sender: Any) {
        setEditController(mode:ChannelSettingEditVC.EditMode.addChannel)
    }
    
    
    
    func refresh() {
        
        var groupName = ChannelManager.groupNameRoot
        let path = channelSettingVC.currentPath
        if channelSettingVC.isFocusedPath {
            if path.count > 1 {
                groupName = path[path.count - 2]
            }
        }
        else {
            if path.count > 0 {
                groupName = path.last!
            }
        }
        titleLabel.text = "Add to group:\(groupName)"
    }


    
    func setEditController(mode:ChannelSettingEditVC.EditMode) {
        channelSettingVC.setEditController(mode:mode)
    }
    
    
    
    
    
    
}
