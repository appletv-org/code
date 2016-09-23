//
//  ChannelSettinsVC.swift
//  iptv
//
//  Created by Александр Колганов on 19.09.16.
//  Copyright © 2016 Home. All rights reserved.
//

import UIKit
import CoreData


class ChannelCell : UICollectionViewCell {
    
     static let reuseIdentifier = "ChannelCell"
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var label: UILabel!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // These properties are also exposed in Interface Builder.
        imageView.adjustsImageWhenAncestorFocused = true
        imageView.clipsToBounds = false
        
        label.alpha = 0.0
    }
    
    // MARK: UICollectionReusableView
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        // Reset the label's alpha value so it's initially hidden.
        label.alpha = 0.8
    }
    
    // MARK: UIFocusEnvironment
    
    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        /*
         Update the label's alpha value using the `UIFocusAnimationCoordinator`.
         This will ensure all animations run alongside each other when the focus
         changes.
         */
        coordinator.addCoordinatedAnimations({
            if self.isFocused {
                self.label.alpha = 1.0
            }
            else {
                self.label.alpha = 0.8
            }
            }, completion: nil)
    }
}


class ChannelSettingsVC : UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    
    @IBOutlet weak var channelsView: UICollectionView!
    
    var parentGroups : [Group] = []
    var groups : [Group] = []
    var channels: [Channel] = []
    
    var context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
 
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        
        channelsView.delegate = self
        channelsView.dataSource = self
        
        let requestGroup : NSFetchRequest<Group> =  Group.fetchRequest()
        requestGroup.predicate = NSPredicate(format: "parent == nil")
        if let resultGroups = try? context.fetch(requestGroup) {
            groups = resultGroups
        }
        
        let requestChannels : NSFetchRequest<Channel> =  Channel.fetchRequest()
        if let resultChannels = try? context.fetch(requestChannels) {
            channels = resultChannels
        }
        
        
    }
    
    
    //---- UICollectionViewDataSource ------
    
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return  groups.count + channels.count + 1
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = self.channelsView.dequeueReusableCell(withReuseIdentifier: ChannelCell.reuseIdentifier, for: indexPath) as! ChannelCell
        
        
        if indexPath.row == groups.count + channels.count {
            cell.label.text = "Add"
        }
        else {
            if indexPath.row < groups.count {
                cell.label.text = groups[indexPath.row].name ?? ""
            }
            else {
                cell.label.text = channels[indexPath.row - groups.count].name ?? ""
            }
        }
        return cell
    }
    
    //---- UICollectionViewDelegate ------
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if(indexPath.row == groups.count + channels.count) {
            self.addM3uList()
        }
        
    }
    
 
    func addM3uList() -> Void {
        
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
                let items = try parseM3u(string:url)
                if items.count > 0  {
                    
                    
                    let parentGroup = Group.Insert()
                    parentGroup.name = name
                    
                    var groups = [String: Group]()
                    for item in items {
                        
                        var group :Group? = parentGroup

                        if let groupName = item.group {
                            group = groups[groupName]
                            if group == nil {
                                group = Group.Insert()
                                group?.name = groupName
                                group?.parent = parentGroup
                            }
                        }
                    
                        let channel = Channel.Insert()
                        channel.name = item.name
                        channel.url = item.url
                        if group != nil {
                            channel.addToGroups(group!)
                        }
                    }
                    
                }
                CoreDataManager.instance.saveContext()
                self.labels.append(name)
                self.channelsView.reloadData()
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
    
}


