//
//  ChannelSettingEditVC.swift
//  iptv
//
//  Created by Alexandr Kolganov on 20.12.16.
//  Copyright © 2016 Home. All rights reserved.
//

import UIKit

class ChannelSettingEditVC : FocusedViewController {
    
    enum EditMode {
        case edit,
             addChannel, addGroup, addRemoteGroup
    }
    
    
    var path : [String]!
    var mode : EditMode = .edit
    var dirElement: DirElement?
    
    @IBOutlet weak var nameStack: UIStackView!
    @IBOutlet weak var nameTextField: UITextField!
    
    @IBOutlet weak var urlStack: UIStackView!
    @IBOutlet weak var urlTextField: UITextField!
    
    @IBOutlet weak var publicStack: UIStackView!
    @IBOutlet weak var updateStack: UIStackView!
    @IBOutlet weak var infoLabel: UILabel!
    
    @IBOutlet weak var saveButton: UIButton!
    
    @IBOutlet weak var cancelButton: UIButton!
    
    
    func setParameters(_ path : [String], mode:EditMode) {
        
        self.path = path
        self.mode = mode
        self.dirElement = ChannelManager.findDirElement(path)
        
        if dirElement == nil {
            infoLabel.text = "Path is not exist"
            return
        }
        
        let remoteGroup = ChannelManager.findParentRemoteGroup(path)
        let haveRemoteGroup = (remoteGroup != nil)
        
        let reservedIndex = ChannelManager.reservedNames.index(where:{$0 == dirElement!.name})
        
        let editable = !( mode == .edit && (haveRemoteGroup || reservedIndex != nil) )
        
        // name
        nameTextField.text = (mode == .edit) ? dirElement!.name : ""
        nameTextField.isEnabled = editable
        
        //url 
        if mode == .edit {
            if let url = dirElement!.url {
                urlStack.isHidden = false
                urlTextField.text = url
            }
            else {
                urlStack.isHidden = true
            }
            urlTextField.isEnabled = editable
        }
        else {
            let urlIsHidden = (mode == .addGroup)
            urlStack.isHidden = urlIsHidden
            urlTextField.text = "http://"
        }
        urlTextField.isEnabled = editable
        
        
        //public
        publicStack.isHidden = (mode != .addRemoteGroup)
        
        //info (always visible)
        var info = ""
        if mode == .edit {
            if haveRemoteGroup {
                info = "You can not edit the channels/groups are located into remote group: \(remoteGroup!.name)"
            }
            if (reservedIndex != nil) {
                info = "You can not change reserved group"
            }
        }
        infoLabel.text =  info
        
        //buttons
        saveButton.titleLabel?.text = (mode == .edit) ? "Save" : "Add"
        
        saveButton.isEnabled = editable
        cancelButton.isEnabled = editable
        
        //self.view.setNeedsLayout()
        //self.view.layoutIfNeeded()
        
    }
    
    @IBAction func saveAction(_ sender: Any) {
        
        var err:Error? = nil
        if mode == .edit {
            let isChangeName = (dirElement!.name != nameTextField.text)
            
            
            if case .channel(_) = dirElement! {
                err = ChannelManager.changeChannel(path!, name: nameTextField.text!, url: nameTextField.text!)
            }
            else if case .group(_) = dirElement! {
                err = ChannelManager.changeGroup(path!, name: nameTextField.text!)
            }
            
            if err == nil {
                if isChangeName {
                    if let channelSettingsVC = self.parent as? ChannelSettingsVC {
                        _ = path.popLast()
                        path.append(nameTextField.text!)
                        channelSettingsVC.reloadPath(path)
                    }
                
                }
            }
        }
            
        else if mode == .addGroup {
            err = ChannelManager.addGroup(path, name:nameTextField.text!)
            if err == nil {
                if let channelSettingsVC = self.parent as? ChannelSettingsVC {
                    channelSettingsVC.reloadPath(path)
                }

            }
        }
            
        else if mode == .addChannel {
            err = ChannelManager.addChannel(path, name:nameTextField.text!, url:urlTextField.text!)
            if err == nil {
                if let channelSettingsVC = self.parent as? ChannelSettingsVC {
                    channelSettingsVC.reloadPath(path)
                }
            }
        }
        
        else if mode == .addRemoteGroup {
            err = ChannelManager.addRemoteGroup(path, name: nameTextField.text!, url: urlTextField.text!)
            if err == nil {
                if let channelSettingsVC = self.parent as? ChannelSettingsVC {
                    channelSettingsVC.reloadPath(path)
                }
            }
        }
        
        infoLabel.text = err != nil ? errMsg(err!) : ""
        
    }
    
    @IBAction func cancelAction(_ sender: Any) {
        if mode == .edit {
            nameTextField.text = dirElement!.name
            if let url = dirElement!.url {
                urlTextField.text = url
            }
        }
        else {
            if let channelSettingsVC = self.parent as? ChannelSettingsVC {
                channelSettingsVC.setBottomPanel(operation:.add)
            }
        }
        
    }
    
    

}
