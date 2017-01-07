//
//  ChannelSettingEditVC.swift
//  iptv
//
//  Created by Alexandr Kolganov on 20.12.16.
//  Copyright © 2016 Home. All rights reserved.
//

import UIKit


class ChannelSettingEditVC : BottomController, BottomControllerProtocol {
    
    enum EditMode {
        case edit,
             addChannel, addGroup, addRemoteGroup
    }
    
    
    var mode : EditMode = .edit
    
    @IBOutlet weak var fieldsStack: UIStackView!
    @IBOutlet weak var nameStack: UIStackView!
    @IBOutlet weak var nameTextField: UITextField!
    
    @IBOutlet weak var urlStack: UIStackView!
    @IBOutlet weak var urlTextField: UITextField!
    
    @IBOutlet weak var publicStack: UIStackView!
    @IBOutlet weak var updateStack: UIStackView!
    @IBOutlet weak var infoLabel: UILabel!
    
    @IBOutlet weak var saveButton: UIButton!
    
    @IBOutlet weak var cancelButton: UIButton!
    
    
    func refresh() {
        
        
        if channelSettingVC.dirElement == nil {
            infoLabel.text = "Path is not exist"
            return
        }
        
        let haveRemoteGroup = (channelSettingVC.remoteGroup != nil)
        
        let reservedIndex = ChannelManager.reservedNames.index(where:{$0 == channelSettingVC.dirElement!.name})
        
        let editable = !( mode == .edit && (haveRemoteGroup || reservedIndex != nil) )
        
        // name
        nameTextField.text = (mode == .edit) ? channelSettingVC.dirElement!.name : ""
        nameTextField.isEnabled = editable
        
        //url 
        if mode == .edit {
            if let url = channelSettingVC.dirElement!.url {
                
                urlStack.setSureHidden(false)
                urlTextField.text = url
            }
            else {
                urlStack.setSureHidden(true)
            }
        }
        else {
            urlStack.setSureHidden(mode == .addGroup)
            urlTextField.text = "http://"
        }
        urlTextField.isEnabled = editable
        
        
        //public
        publicStack.setSureHidden(mode != .addRemoteGroup)
        
        //info (always visible)
        var info = ""
        if mode == .edit {
            if haveRemoteGroup {
                info = "You can not edit the channels/groups are located into remote group: \(channelSettingVC.remoteGroup!.name)"
            }
            if (reservedIndex != nil) {
                info = "You can not change reserved group"
            }
        }
        infoLabel.text =  info
        
        //buttons
        saveButton.setTitleForAllStates((mode == .edit) ? "Save" : "Add")
        
        saveButton.isEnabled = editable
        cancelButton.isEnabled = editable
        
        self.view.setNeedsLayout()
        
    }
    
    @IBAction func saveAction(_ sender: Any) {
        
        var err:Error? = nil
        if mode == .edit {
            let isChangeName = (channelSettingVC.dirElement!.name != nameTextField.text)
            
            
            if case .channel(_) = channelSettingVC.dirElement! {
                err = ChannelManager.changeChannel(channelSettingVC.currentPath, name: nameTextField.text!, url: nameTextField.text!)
            }
            else if case .group(_) = channelSettingVC.dirElement! {
                err = ChannelManager.changeGroup(channelSettingVC.currentPath, name: nameTextField.text!)
            }
            
            if err == nil {
                if isChangeName {
                    var path = channelSettingVC.currentPath
                    let _ = path.popLast()
                    path.append(nameTextField.text!)
                    channelSettingVC.reloadPath(path)
                }
            }
        }
        else { //add to parent group
            var path = channelSettingVC.currentPath
            if channelSettingVC.isFocusedPath {
                let _ = path.popLast()
            }
            
            
            if mode == .addGroup {
                err = ChannelManager.addGroup(path, name:nameTextField.text!)
            }
            else if mode == .addChannel {
                err = ChannelManager.addChannel(path, name:nameTextField.text!, url:urlTextField.text!)
            }
            
            else if mode == .addRemoteGroup {
                err = ChannelManager.addRemoteGroup(path, name: nameTextField.text!, url: urlTextField.text!)
            }
            if err == nil {
                path.append(nameTextField.text!)
                channelSettingVC.reloadPath(path)
            }

        }
        
        infoLabel.text = err != nil ? errMsg(err!) : ""
        
    }
    
    @IBAction func cancelAction(_ sender: Any) {
        if mode == .edit {
            nameTextField.text = channelSettingVC.dirElement!.name
            if let url = channelSettingVC.dirElement!.url {
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
