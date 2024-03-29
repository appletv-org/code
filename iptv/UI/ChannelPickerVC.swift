//
//  ChannelPickerEmbededVC.swift
//  iptv
//
//  Created by Alexandr Kolganov on 31.10.16.
//  Copyright © 2016 Home. All rights reserved.
//

import UIKit


class ChannelCell : UICollectionViewCell {
    
    static let reuseIdentifier = "ChannelCell"
    static let focusIncrease : CGFloat = 30
    
    static let imageGroup = UIImage(named: "group")
    static let imageChannel = UIImage(named: "channel")
    static let imageRemoteGroup = UIImage(named: "reload")
    
    
    @IBOutlet weak var channelView: UIView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var nameIntoImage: UILabel!
    @IBOutlet weak var remoteImageView: UIImageView!
    
    @IBOutlet weak var niiHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var niiWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var niiCenterYConstraint: NSLayoutConstraint!
    @IBOutlet weak var niiCenterXConstraint: NSLayoutConstraint!
    
    
    
    var _element : DirElement?
    var element : DirElement //group or channel
        {
        get {
            return _element!
        }
        set(newElement) {
            _element = newElement
            var remoteImage : UIImage? = nil
            switch newElement {
            case .group(let group):
                label.text = group.name
                //print("set label text:\(group.name)")
                nameIntoImage.text = group.name
                nameIntoImage.numberOfLines = 1
                //nameIntoImage.backgroundColor = UIColor.red
                niiCenterYConstraint.constant = 8
                niiCenterXConstraint.constant = -10
                niiWidthConstraint.constant = -46
                niiHeightConstraint.constant = -92
                imageView.image = ChannelCell.imageGroup
                
                if group.remoteInfo != nil {
                    remoteImage = ChannelCell.imageRemoteGroup
                }
                
            case .channel(let channel):
                label.text = channel.name
                nameIntoImage.text = channel.name
                nameIntoImage.numberOfLines = 2
                //nameIntoImage.backgroundColor = UIColor.red
                niiCenterYConstraint.constant = -8
                niiCenterXConstraint.constant = 2
                niiWidthConstraint.constant = -22
                niiHeightConstraint.constant = -90
                imageView.image = ChannelCell.imageChannel
                ProgramManager.instance.getIcon(channel: channel.name, completion: { (data) in
                    if data != nil {
                        if let image = UIImage(data: data!) {
                            self.imageView.image = image
                            self.nameIntoImage.text = ""
                        }
                    }
                })
            }
            remoteImageView.image = remoteImage
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.channelView.layer.cornerRadius = 20
        //self.channelView.layer.borderColor = UIColor.darkGray.cgColor //selected color
        //self.channelView.layer.borderWidth = 0.0
    }
    
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        self.selectedCell(isSelected: false)
        self.focusedCell(isFocused: false)
        
    }
    
    func focusedCell(isFocused : Bool) {
        if isFocused {
            self.channelView.transform = CGAffineTransform(scaleX:1.2, y:1.2)
            self.channelView.backgroundColor = UIColor.white
        }
        else {
            self.channelView.transform = CGAffineTransform.identity
            self.channelView.backgroundColor = UIColor.clear
        }
    }
    
    func selectedCell(isSelected : Bool) {
        if(isSelected) {
            self.channelView.backgroundColor = UIColor.white
            //self.label.textColor = UIColor.white
            //self.channelView.layer.borderWidth = 5.0
        }
        else {
            self.channelView.backgroundColor = UIColor.clear
            //self.label.textColor = UIColor.darkGray
            //self.channelView.layer.borderWidth = 0.0
         }
    }
    
    
}

protocol DirectoryStackDelegate : class {
    func setupPath(_ path: [String], isParent : Bool)
}

class DirectoryStack:UIStackView {
    
    var _path : [String] = []
    weak var delegate : DirectoryStackDelegate?
    
    
    func createButton(_ title:String, tag:Int) -> UIButton {
        let button = UIButton(type: .roundedRect)
        button.contentEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        button.tag = tag
        button.setTitle(title + " >", for: .normal)
        button.setTitleColor(tintColor, for: .disabled)
        button.addTarget(self, action: #selector(DirectoryStack.changeDirAction(_:)), for: .primaryActionTriggered)
        return button
    }
    
    
    
    var path : [String] {
        get {
            return _path
        }
        set(newPath) {
            changePath(newPath)
        }
        
    }
    
    func changePath(_ path: [String]) -> Void{
        
        /*
        //check path not changed
        if _path.count == path.count  {
            var isEqual = true
            for i in 0..<path.count {
                if path[i] != _path[i] {
                    isEqual = false
                    break
                }
            }
            if isEqual {
                return
            }
        }
         */
        
        
        //delete all button except last item
        while arrangedSubviews.count > 1 {
            arrangedSubviews[arrangedSubviews.count - 2].removeFromSuperview()
        }
        
        //insert buttons
        
        //root button
        
        let button = createButton(ChannelManager.root.name, tag:0)
        insertArrangedSubview(button, at: 0)
        
        for i in 0..<path.count {
            let button = createButton(path[i], tag:i+1)
            insertArrangedSubview(button, at: i+1)
        }
        _path = path
    }
    
    
    @objc func changeDirAction(_ sender:UIButton?) {
        let index = sender!.tag
        
        let newPath = Array(path[0..<index])
        delegate?.setupPath(newPath, isParent: true)
    }
    
}


class ChannelPickerCollectionView : FocusedCollectionView {
    
}

protocol ChannelPickerDelegate : class {
    func focusedPath(chooseControl: ChannelPickerVC,  path:[String])
    func changePath(chooseControl: ChannelPickerVC,  path:[String])
    func selectedPath(chooseControl: ChannelPickerVC,  path:[String])
    
}

extension ChannelPickerDelegate  {
    func focusedPath(chooseControl: ChannelPickerVC,  path:[String])    {}
    func changePath(chooseControl: ChannelPickerVC,  path:[String])     {}
    func selectedPath(chooseControl: ChannelPickerVC,  path:[String])   {}    
}

class ChannelPickerVC : FocusedViewController, DirectoryStackDelegate {
    
    var path: [String] = [] //current directory path for DirectoryStack
    var groupInfo : GroupInfo = ChannelManager.root //current group info for DirectroryStack
    //private var focusedIndex: Int = 0
    var showFocusedElement = true
    
    var showAllGroup = false
    var showHiddenGroup = false
    
    
    weak var delegate : ChannelPickerDelegate?
    
    @IBOutlet weak var directoryContainerView: ContainerFocused!
    @IBOutlet weak var directoryStack: DirectoryStack!
 
    @IBOutlet weak var collectionView: ChannelPickerCollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.remembersLastFocusedIndexPath = false //we use focusedIndex
        
        collectionView.setFocusPause(0.2)
        
        directoryStack.delegate = self
        
        
        directoryContainerView.focusedFunc = { () -> [UIFocusEnvironment]? in
                let stackSubViews = self.directoryStack.arrangedSubviews
                if(stackSubViews.count >= 2) {
                    return [stackSubViews[stackSubViews.count-2]]
            }
            return []
        }
        directoryContainerView.setFocusPause(0.2)
        //setupPath(path)
    }
    
    static func loadFromIB() -> ChannelPickerVC {
        let mainStoryboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        let channelPickerVC = mainStoryboard.instantiateViewController(withIdentifier: "ChannelPickerVC") as! ChannelPickerVC
        channelPickerVC.view.translatesAutoresizingMaskIntoConstraints = false
        return channelPickerVC
    }
    
    
    static func insertToView(parentController: UIViewController, parentView: UIView) -> ChannelPickerVC {
        let mainStoryboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        let channelPickerVC = mainStoryboard.instantiateViewController(withIdentifier: "ChannelPickerVC") as! ChannelPickerVC
        channelPickerVC.view.translatesAutoresizingMaskIntoConstraints = false
        parentController.containerAdd(childViewController: channelPickerVC, toView:parentView)
        return channelPickerVC

    }

    
    //setup UI for this path
    func setupPath(_ path: [String], isParent : Bool = false) {
        
        self.path = path
        if !isParent && path.count > 0 {
            self.path = Array(path[0..<path.count-1])
        }
        
        self.collectionView.focusedIndex = IndexPath(row: 0, section: 0)
        
        if let group =  ChannelManager.findGroup(self.path) {
            groupInfo = group
            if !isParent && path.count > 0 {  //find index
                let index = groupInfo.findDirIndex(path.last!)
                if index >= 0 {
                    self.collectionView.focusedIndex = IndexPath(row: index, section: 0)
                }
            }
        }
        else {
            groupInfo = ChannelManager.root
            self.path = []
        }
        
        directoryStack.path = self.path
        
        delegate?.changePath(chooseControl: self, path: self.path)
        
        collectionView.performBatchUpdates({
            self.collectionView.reloadSections(IndexSet(integer:0))
        }, completion: { completed -> Void in
            if self.groupInfo.countDirElements() > 0 {
                self.viewToFocus = self.collectionView
            }
            else {
                if let focusedEnvironments = self.directoryContainerView.focusedFunc!(),
                    focusedEnvironments.count == 1,
                    let button = focusedEnvironments[0] as? UIButton
                {
                    self.viewToFocus = button
                }
            }
        })
    
    }
    
    
    func showAsSelectedElement(_ name:String, animated:Bool = false) {
        let ind = groupInfo.findDirIndex(name)
        if ind >= 0 {
            let index = IndexPath( row:ind, section:0)
            collectionView.showElement(index, animated: animated)
            if let cell = collectionView.cellForItem(at: index) as? ChannelCell {
                cell.selectedCell(isSelected: true)
            }
            //collectionView.scrollToItem(at: IndexPath( row:ind, section:0), at: .centeredHorizontally, animated: animated)
        }
    }
    
    
}

extension ChannelPickerVC : UICollectionViewDataSource, UICollectionViewDelegate
{
    //---- UICollectionViewDataSource ------
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        var ret = groupInfo.groups.count + groupInfo.channels.count
        if showAllGroup && groupInfo.groups.count > 0 {
            ret += 1
        }
        
        if showHiddenGroup && groupInfo.remoteInfo != nil {
            ret += 1
        }
        //print("number items in section:\(ret)")
        return ret
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ChannelCell.reuseIdentifier, for: indexPath) as! ChannelCell
        
        var index = indexPath.row
        
        if showAllGroup && groupInfo.groups.count > 0 {
            if index == 0 {
                let group = GroupInfo(name: ChannelManager.groupNameAll)
                cell.element = .group(group)
                return cell
            }
            index -= 1
        }
        
        if index < groupInfo.groups.count {
            cell.element = .group(groupInfo.groups[index])
             //print("group items \(index):\(groupInfo.groups[index].name)")
            return cell
        }
        index -= groupInfo.groups.count


        if index < groupInfo.channels.count {
            cell.element = .channel(groupInfo.channels[index])
        }
        
        if showHiddenGroup && groupInfo.remoteInfo != nil {
            if index == groupInfo.channels.count {
                let group = GroupInfo(name: ChannelManager.groupNameHidden)
                cell.element = .group(group)
                return cell
            }
        }
        
        return cell
    }
    
    //---- UICollectionViewDelegate ------
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        var index = indexPath.row
        
        if showAllGroup && groupInfo.groups.count > 0 {
            if index == 0 {
                var newPath = path
                newPath.append(ChannelManager.groupNameAll)
                setupPath(newPath, isParent: true)
                return
            }
            index -= 1
        }

        
        if index < groupInfo.groups.count {
            var newPath = path
            newPath.append(groupInfo.groups[index].name)
            setupPath(newPath, isParent: true)
            return
        }
        index -= groupInfo.groups.count
        

        
        if index >= 0 && index < groupInfo.channels.count {
            delegate?.selectedPath(chooseControl: self, path: path + [groupInfo.channels[index].name])
        }
        
        if showHiddenGroup && groupInfo.remoteInfo != nil {
            if index == groupInfo.channels.count {
                var newPath = path
                newPath.append(ChannelManager.groupNameHidden)
                setupPath(newPath, isParent: true)
                return
            }
        }
    }
    
    
    func indexPathForPreferredFocusedView(in collectionView: UICollectionView) -> IndexPath? {
        if  let indexPath = self.collectionView.focusedIndex {
            self.collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: false)
            return indexPath
        }
        return nil
        
    }
    

    func collectionView(_ collectionView: UICollectionView, didUpdateFocusIn context: UICollectionViewFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        
        
        /*
        //change focused
        if let indexPath = context.nextFocusedIndexPath {
            focusedIndex = indexPath.row
            if let cell = collectionView.cellForItem(at: indexPath) as? ChannelCell {
                delegate?.focusedPath(chooseControl: self, path: path + [cell.element.name])
            }
        }
         */
        let prevIndex = context.previouslyFocusedIndexPath
        let nextIndex  = context.nextFocusedIndexPath
        
        coordinator.addCoordinatedAnimations({
            if nextIndex != nil {
                if let cell = collectionView.cellForItem(at: nextIndex!) as? ChannelCell {
                    cell.selectedCell(isSelected: false)
                    cell.focusedCell(isFocused: true)
                    //cell.channelView.transform = CGAffineTransform(scaleX:1.2, y:1.2)
                    //cell.channelView.backgroundColor = UIColor.white
                    //self.collectionView.focusedIndex = nextIndex!.row
                    self.delegate?.focusedPath(chooseControl: self, path: self.path + [cell.element.name])
                }
            }

            if prevIndex != nil {
                if let cell = collectionView.cellForItem(at: prevIndex!) as? ChannelCell {
                    cell.focusedCell(isFocused: false)
                    //cell.channelView.transform = CGAffineTransform.identity
                    //cell.channelView.backgroundColor = UIColor.clear
                    if self.showFocusedElement && nextIndex == nil {
                        cell.selectedCell(isSelected: true)
                        //cell.channelView.layer.borderWidth = 5.0
                        //cell.channelView.layer.borderColor = UIColor.blue.cgColor
                    }
                    else {
                        cell.selectedCell(isSelected: false)
                    }
                }
                
                
            }
            
        }, completion: nil)

    }
    
    
}
