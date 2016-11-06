//
//  ChannelSettinsVC.swift
//  iptv
//
//  Created by Александр Колганов on 19.09.16.
//  Copyright © 2016 Home. All rights reserved.
//

import UIKit


class ChannelSettingsVC : UIViewController, ChannelPickerProtocol {

    var currentPath = [String]()
    
    weak var channelPickerVC : ChannelPickerVC?
    @IBOutlet weak var channelPickerView: UIView!
    
    @IBOutlet weak var editButton: UIButton!
    @IBOutlet weak var currentLabel: UILabel!
    
    @IBAction func addAction(_ sender: AnyObject) {
        addM3uListDialog()
    }
    
    @IBAction func delAction(_ sender: AnyObject) {
        
        if currentPath.count > 1 { //we cannot del root group
            
            //find prev elem
            var index = 0
            let parentGroup = ChannelManager.findParentGroup(currentPath)
            if parentGroup != nil {
                index = parentGroup!.findDirIndex(currentPath.last!)
            }
            
            if ChannelManager.delPath(currentPath) {
                if (parentGroup != nil && index >= 0) {
                    if index >= parentGroup!.countDirElements() {
                        index -= 1
                    }
                    if index < 0 {
                        index = 0
                    }
                    currentPath = Array(currentPath[0..<currentPath.count])
                    if let nextElement = parentGroup?.findDirElement(index: index) {
                        currentPath += [nextElement.name]
                    }
                    channelPickerVC!.setupPath(currentPath)
                }
                
                ChannelManager.save()
            }
        }
        
    }
    
    
    override func viewDidLoad() {
        
        let mainStoryboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        channelPickerVC = mainStoryboard.instantiateViewController(withIdentifier: "ChannelPickerVC") as? ChannelPickerVC
        
        
        channelPickerVC!.view.translatesAutoresizingMaskIntoConstraints = false
        channelPickerVC!.delegate = self
        self.containerAdd(childViewController: channelPickerVC!, toView:channelPickerView)
        super.viewDidLoad()
        
        
    }
    
    func focusedPath(chooseControl: ChannelPickerVC,  path:[String]) {
        currentPath = path
        currentLabel.text = path.last
    }
    
    
    func addM3uListDialog() -> Void {
        
        let alertController = UIAlertController(title: "New playlist", message: nil, preferredStyle: .alert)
        
        // Add two text fields for text entry.
        alertController.addTextField { textField in
            // Customize the text field.
            //textField.text = "Приморская локальная сеть"
            textField.text = "Edem"
            textField.placeholder = NSLocalizedString("Name", comment: "")
        }
        alertController.addTextField { textField in
            //textField.text = "http://tv.plsspb.ru/tv.m3u"
            textField.text = "https://edem.tv/playlists/uplist/e7deff4ce5cd4097ca4b2ef7c2f875ad/edem_pl.m3u8"
            textField.placeholder = NSLocalizedString("Url", comment: "")
            // Specify a custom input accessory view with a descriptive title.
            
        }
        
        
        // Create the actions.
        alertController.addAction(UIAlertAction(title: "Add", style: .default) { [unowned alertController] _ in
            
            guard let name = alertController.textFields?.first?.text , name != "",
                  let url =  alertController.textFields?.last?.text, url != ""
            else {
                print("Please fill all fields")
                return
            }
            
            do {
                try self.addM3uList(name:name, url:url)
            }
            catch let error {
                let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
                self.present(alert, animated: true, completion: nil)
            }
        })
        
        /*
         The cancel action is created the the `Cancel` style and no title.
         This will allow us to capture the user clicking the menu button to
         cancel the alert while not showing a specific cancel button.
         */
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
            print("The \"Text Entry\" alert's cancel action occured.")
        })
        
        present(alertController, animated: true, completion: nil)
        
    }
    
    
    func addM3uList(name:String, url:String) throws -> Void {

        try ChannelManager.addM3uList(name: name, url: url)
        ChannelManager.save()
        //changePath([ChannelManager.root.name])

    }

    
    /*
    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        super.didUpdateFocus(in: context, with: coordinator)
        
        if let nextFocusedItem = context.nextFocusedItem {
            //print("nextFocusedItem : \(nextFocusedItem)")
            focusedItem = nextFocusedItem
            if let cellItem = nextFocusedItem as? ChannelCell {
                currentItem = cellItem.element
                currentLabel.text = currentItem!.name
            }
        }
        
        /*
        if let previouslyFocusedItem = context.previouslyFocusedItem {
            print("previouslyFocusedItem : \(previouslyFocusedItem)")
        }
         */
        
    }
     */


}



