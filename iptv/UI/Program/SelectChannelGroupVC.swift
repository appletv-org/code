//
//  ChannelsFilterVC.swift
//  iptv
//
//  Created by Alexandr Kolganov on 14.12.16.
//  Copyright © 2016 Home. All rights reserved.
//

import UIKit

protocol  SelectChannelGroupDelegate : class {
    func selectedGroup(_ path: [String]?)
}

class SelectChannelGroupVC : FocusedViewController {
    
    var groupPath : [String]?

    var channelPickerVC : ChannelPickerVC!
    
    weak var delegate : SelectChannelGroupDelegate?
    
    @IBOutlet weak var channelPickerView: UIView!
    @IBOutlet weak var currentGroup: UILabel!

    @IBAction func allChannelsButtonAction(_ sender: Any) {
        self.dismiss(animated: false, completion: {
            self.delegate?.selectedGroup(nil)
        })
    }

    @IBAction func selectGroupAction(_ sender: Any) {
        self.dismiss(animated: false, completion: {
            self.delegate?.selectedGroup(self.groupPath)
        })
        
    }
    
    
    static func loadFromIB() -> SelectChannelGroupVC {
        let mainStoryboard = UIStoryboard(name: "Program", bundle: Bundle.main)
        let selectChannelGroupVC = mainStoryboard.instantiateViewController(withIdentifier: "SelectChannelGroupVC") as! SelectChannelGroupVC
        return selectChannelGroupVC
    }
    
    override func viewDidLoad() {
        
        channelPickerVC = ChannelPickerVC.insertToView(parentController: self, parentView: channelPickerView)
        channelPickerVC.delegate = self
        //channelPickerVC.showAllGroup = true
        if groupPath == nil {
            groupPath = []
        }
        
        channelPickerVC.setupPath(groupPath!)
        
        currentGroup.text = "Channels > " + groupPath!.joined(separator: " > ")
        
        
        super.viewDidLoad()
        

    }
}

extension SelectChannelGroupVC : ChannelPickerDelegate {
    func changePath(chooseControl: ChannelPickerVC,  path:[String]) {
        groupPath = path
        currentGroup.text = "Channels > " + path.joined(separator: " > ")
    }
}
