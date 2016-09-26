//
//  ChannelSettinsVC.swift
//  iptv
//
//  Created by Александр Колганов on 19.09.16.
//  Copyright © 2016 Home. All rights reserved.
//

import UIKit
import CoreData


class ChannelSettingsVC : UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, DirectoryStackProtocol {


    @IBOutlet weak var directoryStackView: UIStackView!

    @IBOutlet weak var channelsView: UICollectionView!
    
    @IBAction func addAction(_ sender: AnyObject) {
        addM3uListDialog()
    }
    
    var groupInfo : GroupInfo!
    var directoryStack : DirectoryStack!
    
 
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        
        channelsView.delegate = self
        channelsView.dataSource = self
        channelsView.remembersLastFocusedIndexPath = true
        
        directoryStack = DirectoryStack(directoryStackView)
        directoryStack.delegate = self
        
        changeGroup(ChannelManager.root)
        
    }
    
    func changeGroup(_ groupInfo: GroupInfo) {
        self.groupInfo = groupInfo
        self.channelsView.reloadData()
        
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
            cell.element = groupInfo.groups[index]
            return cell
        }
        
        index -= groupInfo.groups.count
        if index < groupInfo.channels.count {
            cell.element = groupInfo.channels[index]
        }

        return cell
    }
    
    //---- UICollectionViewDelegate ------
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        var index = indexPath.row
        
        if index < groupInfo.groups.count {
            directoryStack!.push(groupInfo.groups[index])
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
        let items = try parseM3u(string:url)
        if items.count > 0  {
            
            var groupsList : [String:[M3uItem]] = ["All":[]]
            for item in items {
                groupsList["All"]!.append(item)
                if let groupName = item.group {
                    var groupList = groupsList[groupName]
                    if groupList == nil {
                        groupsList[groupName] = []
                    }
                    
                    groupsList[groupName]!.append(item)
                    
                }
            }
            
            
            
            //add new list to root
            let parentGroup = GroupInfo(name:name, groups:[], channels:[])
            ChannelManager.root.groups.append(parentGroup)
            
            for (nameGroup,groupList) in groupsList {
                
                var group = parentGroup
                if groupsList.count > 1 { //not only all
                    group = GroupInfo(name:nameGroup, groups:[], channels:[])
                    parentGroup.groups.append(group)
                    print("add group:\(group.name) to parent:\(parentGroup.name)")
                }
                
                for item in groupList {
                    let channel = ChannelInfo(name:item.name!, url:item.url!)
                    group.channels.append(channel)
                     print("add channel:\(channel.name) to group:\(group.name)")
                }
                
            }
            ChannelManager.save()
            
        }

        self.changeGroup(ChannelManager.root)
        
    }
    
    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        super.didUpdateFocus(in: context, with: coordinator)
        
        if let nextFocusedView = context.nextFocusedView {
            print("nextFocusedView : \(nextFocusedView)")
        }
        if let prevFocusedView = context.previouslyFocusedView {
            print("prevFocusedView : \(prevFocusedView)")
        }
        
    }

    
    
    
}

protocol DirectoryStackProtocol {
    func changeGroup(_ group: GroupInfo)
}

class DirectoryStack {
    
    var parentGroups : [GroupInfo] = [ChannelManager.root]
    let stackView : UIStackView
    var delegate : DirectoryStackProtocol?
    
    init(_ stackView:UIStackView) {
        self.stackView = stackView
    }
    
    func removeLastButton() -> Void { //last element is label
        let index = stackView.subviews.count-2
        if index >= 0 {
            let view = stackView.arrangedSubviews[index]
            stackView.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
    }
    
    func addLastButton(_ label: String) -> Void { //last element is label
        
        let popdirButton = UIButton(type: .roundedRect)
        popdirButton.setTitle(label, for: .normal)
        popdirButton.addTarget(self, action: #selector(DirectoryStack.popdirAction(_:)), for: .primaryActionTriggered)
        let index = stackView.subviews.count-1
        popdirButton.tag = index
        stackView.insertArrangedSubview(popdirButton, at: index)

    }
    
    func push(_ group:GroupInfo) -> Void {
        guard let lastLabel = self.stackView.arrangedSubviews.last as? UILabel else {
            print("Not found label")
            return
        }
        
        //add button
        self.addLastButton((parentGroups.last?.name)!)
        
        lastLabel.text = group.name
        parentGroups.append(group)
        delegate?.changeGroup(group)
    }
    
    @objc func popdirAction(_ sender:UIButton?) {
        let index = sender!.tag
        let last = stackView.subviews.count-2
        for _ in index...last {
            removeLastButton()
        }
        parentGroups.removeLast(last-index+1)
        
        guard let lastLabel = self.stackView.arrangedSubviews.last as? UILabel else {
            print("Not found label")
            return
        }
        lastLabel.text = parentGroups.count == 0 ? "Channels" : (parentGroups.last?.name)!
        
        delegate?.changeGroup(parentGroups.last!)
        
    }
    
}



