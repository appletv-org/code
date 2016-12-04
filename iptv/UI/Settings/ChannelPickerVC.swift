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
    
    
    @IBOutlet weak var channelView: UIView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var nameIntoImage: UILabel!
    
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
            switch newElement {
            case .group(let group):
                label.text = group.name
                nameIntoImage.text = group.name
                nameIntoImage.numberOfLines = 1
                //nameIntoImage.backgroundColor = UIColor.red
                niiCenterYConstraint.constant = 8
                niiCenterXConstraint.constant = -10
                niiWidthConstraint.constant = -46
                niiHeightConstraint.constant = -92
                imageView.image = ChannelCell.imageGroup
                
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
            self.label.textColor = UIColor.white
            //self.channelView.layer.borderWidth = 5.0
        }
        else {
            self.label.textColor = UIColor.darkGray
            //self.channelView.layer.borderWidth = 0.0
         }
    }
    
    
}

protocol DirectoryStackProtocol : class {
    func changeDirPath(_ path: [String])
}

class DirectoryStack:UIStackView {
    
    var _path : [String] = []
    weak var delegate : DirectoryStackProtocol?
    
    
    func createButton(_ title:String, tag:Int) -> UIButton {
        let button = UIButton(type: .roundedRect)
        button.contentEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        button.tag = tag
        button.setTitle(title, for: .normal)
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
        var i = 1
        for name in path {
            let button = createButton(name, tag:i)
            
            if i == path.count {
                button.isEnabled = false
            }
            insertArrangedSubview(button, at: i)
            i += 1
        }
        _path = path
    }
    
    
    @objc func changeDirAction(_ sender:UIButton?) {
        let index = sender!.tag
        
        var newPath = [String]()
        if index > 0 {
            newPath = Array(path[0..<index])
        }
        //changePath(newPath)
        delegate?.changeDirPath(newPath)
    }
    
}


class ChannelPickerCollectionView :UICollectionView {
    
    var focusedIndex : Int?
    
    /*
    override var preferredFocusEnvironments: [UIFocusEnvironment] {
        //var ret = super.preferredFocusEnvironments
        if focusedIndex >= 0 {
            self.scrollToItem(at: IndexPath(row:focusedIndex, section:0), at: .centeredHorizontally, animated: false)
            if let cell = cellForItem(at: IndexPath.init(row: focusedIndex, section: 0)) {
                return [cell]
            }
        }
        
        return []
    }
    */
}

protocol ChannelPickerProtocol : class {
    func focusedPath(chooseControl: ChannelPickerVC,  path:[String])
    func changePath(chooseControl: ChannelPickerVC,  path:[String])
    func selectedPath(chooseControl: ChannelPickerVC,  path:[String])
    
}

extension ChannelPickerProtocol  {
    func focusedPath(chooseControl: ChannelPickerVC,  path:[String])    {}
    func changePath(chooseControl: ChannelPickerVC,  path:[String])     {}
    func selectedPath(chooseControl: ChannelPickerVC,  path:[String])   {}    
}

class ChannelPickerVC : UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, DirectoryStackProtocol {
    
    var path: [String] = [] //current directory path for DirectoryStack
    private var groupInfo : GroupInfo = ChannelManager.root //current group info for DirectroryStack
    //private var focusedIndex: Int = 0
    var showFocusedElement = true
    
    var showAllGroup = false
    var showHideGroup = false
    
    var viewToFocus : UIFocusItem?
    
    weak var delegate : ChannelPickerProtocol?
    
    @IBOutlet weak var directoryContainerView: ContainerFocused!
    @IBOutlet weak var directoryStack: DirectoryStack!
 
    @IBOutlet weak var collectionView: ChannelPickerCollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.remembersLastFocusedIndexPath = false //we use focusedIndex
        
        directoryStack.delegate = self
        
        
        directoryContainerView.focusedFunc = { () -> [UIFocusEnvironment]? in
                let stackSubViews = self.directoryStack.arrangedSubviews
                if(stackSubViews.count >= 3) {
                    return [stackSubViews[stackSubViews.count-3]]
            }
            return []
        }
        setupPath(path)
    }
    
    //setup UI for this path
    func setupPath(_ path: [String], isParent : Bool = false) {
        
        self.path = path
        if !isParent && path.count > 0 {
            self.path = Array(path[0..<path.count-1])
        }
        
        self.collectionView.focusedIndex = 0
        
        if let group =  ChannelManager.findGroup(self.path) {
            groupInfo = group
            if !isParent && path.count > 0 {  //find index
                let index = groupInfo.findDirIndex(path.last!)
                if index >= 0 {
                    self.collectionView.focusedIndex = index
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
            //self.collectionView.remembersLastFocusedIndexPath = false
            //self.collectionView.deleteSections(IndexSet(integer:0))
            //self.collectionView.insertSections(IndexSet(integer:0))
            self.collectionView.reloadSections(IndexSet(integer:0))
            //self.collectionView.reloadData()
        }, completion: { completed -> Void in
            
            self.viewToFocus = self.collectionView
            //self.collectionView.remembersLastFocusedIndexPath = true
            //self.viewToFocus = self.collectionView
            //self.setNeedsFocusUpdate()
            //self.updateFocusIfNeeded()
        })
    
    }
    
    
    override var preferredFocusEnvironments: [UIFocusEnvironment] {
        var ret = super.preferredFocusEnvironments
        if viewToFocus != nil {
            ret = [viewToFocus!]
            viewToFocus = nil
        }
        return ret
    }
    
    
    

    //directory Stack Protocol
    func changeDirPath(_ path: [String]) {
        var newPath = path
        if self.path.count > path.count {
           newPath = Array(self.path[0..<path.count+1])
        }
        setupPath(newPath)
    }
    
    
    
    
    //---- UICollectionViewDataSource ------
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        var ret = groupInfo.groups.count + groupInfo.channels.count
        if showAllGroup && groupInfo.groups.count > 0 {
            ret += 1
        }
        return ret
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ChannelCell.reuseIdentifier, for: indexPath) as! ChannelCell
        
        var index = indexPath.row
        
        if showAllGroup && groupInfo.groups.count > 0 {
            if index == 0 {
                let group = GroupInfo(name: ChannelManager.groupNameAll, groups: [GroupInfo](), channels: [ChannelInfo]())
                cell.element = .group(group)
                return cell
            }
            index -= 1
        }
        
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
        
        //index -= groups.count
        //cell.label.text = channels[index].name
    }
    
    
    func indexPathForPreferredFocusedView(in collectionView: UICollectionView) -> IndexPath? {
        if(self.collectionView.focusedIndex != nil) {
            let indexPath = IndexPath(row: self.collectionView.focusedIndex!, section: 0)
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
                    cell.focusedCell(isFocused: true)
                    cell.selectedCell(isSelected: false)
                    //cell.channelView.transform = CGAffineTransform(scaleX:1.2, y:1.2)
                    //cell.channelView.backgroundColor = UIColor.white
                    self.collectionView.focusedIndex = nextIndex!.row
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
