//
//  ChannelSettinsVC.swift
//  iptv
//
//  Created by Александр Колганов on 19.09.16.
//  Copyright © 2016 Home. All rights reserved.
//

import UIKit



class ChannelSettingsVC : UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, DirectoryStackProtocol {

    var groupInfo : GroupInfo = ChannelManager.root
    var path: [String] = [ChannelManager.root.name]
    var currentItem : DirElement? = nil    
    var focusedItem : UIFocusItem? = nil
    
    @IBOutlet weak var directoryStack: DirectoryStack!
    @IBOutlet weak var focusedDirectoryStack: FocusedView!
    @IBOutlet weak var channelsView: UICollectionView!
    
    @IBOutlet weak var focusedActionView: FocusedView!
    
    @IBOutlet weak var editButton: UIButton!
    @IBOutlet weak var currentLabel: UILabel!
    
    @IBAction func addAction(_ sender: AnyObject) {
        addM3uListDialog()
    }
    
    @IBAction func delAction(_ sender: AnyObject) {
        
        var delPath = path
        if let currentName = currentItem?.name {
            delPath = path.map { $0 }  // different array with same objects
            delPath.append(currentName)
            if ChannelManager.delPath(delPath) {
                self.channelsView.reloadData()
                ChannelManager.save()
            }
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        channelsView.delegate = self
        channelsView.dataSource = self
        channelsView.remembersLastFocusedIndexPath = true
        
        directoryStack.delegate = self
        directoryStack.path = self.path
        
        focusedActionView.focusedFunc =  { () -> [UIFocusEnvironment]? in
            if ((self.focusedItem as? ChannelCell) != nil) {
                return [self.editButton]
            }
            return [self.channelsView]
        }
        
        focusedDirectoryStack.focusedFunc = { () -> [UIFocusEnvironment]? in
            if ((self.focusedItem as? ChannelCell) != nil) {
                let stackSubViews = self.directoryStack.arrangedSubviews
                if(stackSubViews.count >= 3) {
                    return [stackSubViews[stackSubViews.count-3]]
                }
            }
            return [self.channelsView]
        }
        
    }
    
    
    //directory Stack Protocol
    func changeStackPath(_ path: [String]) {
        if let group = ChannelManager.findGroup(path) {
            self.path = path
            self.groupInfo = group
            self.channelsView.reloadData()
        }
    }
    
    
    func changePath(_ path: [String]) {
        changeStackPath(path)
        directoryStack.changePath(path)
    }
    
    
    //---- UICollectionViewDataSource ------
    
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return  groupInfo.groups.count + groupInfo.channels.count
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = self.channelsView.dequeueReusableCell(withReuseIdentifier: ChannelCell.reuseIdentifier, for: indexPath) as! ChannelCell
        
        var index = indexPath.row
        
        if index < groupInfo.groups.count {
            cell.element = .group(groupInfo.groups[index])
            return cell
        }
        
        index -= groupInfo.groups.count
        if index < groupInfo.channels.count {
            cell.element = .channel(groupInfo.channels[index])
        }

        return cell
    }
    
    //---- UICollectionViewDelegate ------
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        let index = indexPath.row
        
        if index < groupInfo.groups.count {
            var newPath = path.map({$0})
            newPath.append(groupInfo.groups[index].name)
            changePath(newPath)
            directoryStack.path = newPath
        }
        
        //index -= groups.count
        //cell.label.text = channels[index].name
        
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
                  let url =  alertController.textFields?.last?.text, url != "" else {
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
        changePath([ChannelManager.root.name])

    }
    

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

}




