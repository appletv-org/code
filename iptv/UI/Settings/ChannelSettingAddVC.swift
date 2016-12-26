//
//  ChannelSettingAddVC.swift
//  iptv
//
//  Created by Alexandr Kolganov on 20.12.16.
//  Copyright © 2016 Home. All rights reserved.
//

import UIKit

class ChannelSettingAddVC : FocusedViewController {
    
    var path : [String]?
    var dirElement: DirElement?
    
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("viewDidLoad")
        //addRemoteGroupButton.addTarget(self, action: #selector(ChannelSettingAddVC.addRemoteGroup), for: .touchUpInside)
    }

    override func didMove(toParentViewController parent: UIViewController?) {
        super.didMove(toParentViewController:parent)
        //print("didMove toParentViewController")

    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        //print("viewDidLayoutSubviews")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
    }
    
    func setParameters(_ path:[String]) {
        var groupName = ChannelManager.groupNameRoot
        if path.count > 0 {
            groupName = path.last!
        }
        titleLabel.text = "Add to group:\(groupName)"
    }


    
    func setEditController(mode:ChannelSettingEditVC.EditMode) {
        if let channelSettings = self.parent as? ChannelSettingsVC {
            channelSettings.setEditController(mode:mode)
        }
        
    }
    
    
    
    
    
    
}
