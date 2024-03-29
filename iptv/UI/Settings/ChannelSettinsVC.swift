
//
//  ChannelSettinsVC.swift
//  iptv
//
//  Created by Александр Колганов on 19.09.16.
//  Copyright © 2016 Home. All rights reserved.
//

import UIKit

protocol BottomControllerProtocol {
    func refresh()
}

class BottomController : FocusedViewController {
    weak var channelSettingVC : ChannelSettingsVC!
}


class ChannelSettingsVC : FocusedViewController {
    
    
    static let controllerList = ["ChannelSettingInfoVC", "ChannelSettingEditVC", "ChannelSettingAddVC", "ChannelSettingDeleteVC", "ChannelSettingHideVC", "ChannelSettingCopyVC", "ChannelSettingReorderVC", "ChannelSettingPreviewVC"]
    enum ControllerType : Int  {
        case info = 0, edit, add, delete, hide, copy, reorder, preview
    }
    
    enum OperationType : Int {
        case edit = 0, add, delete, copyMove, reorder, preview
    }
    
    var currentPath = [String]()
    var dirElement : DirElement?
    var remoteGroup : GroupInfo?
    var isHiddenGroup : Bool = false
    var isFocusedPath = false //focus set to channel/group (else we choose group without elements)
    var isReservedName = false
    
    var bottomControllers = [BottomController]()
    var currentBottomController : BottomController!
    
    
    weak var channelPickerVC : ChannelPickerVC!
    

    @IBOutlet weak var channelPickerView: UIView!
    
    @IBOutlet weak var titleLabel: UILabel!
    
    
    @IBOutlet weak var segmentActions: UISegmentedControl!
    
    @IBAction func segmentActionChanged(_ sender: UISegmentedControl) {
        if segmentActions.selectedSegmentIndex == OperationType.edit.rawValue,
            let editVC = bottomControllers[ControllerType.edit.rawValue] as? ChannelSettingEditVC
        {
            editVC.mode = .edit
        }
        setBottomPanel()

        //print("change action")
    }
    
    @IBOutlet weak var bottomView: UIView!
    
    
    func setBottomPanel(operation:OperationType? = nil) {
        
        //title for delete/hide/show
        var title = "Delete"
        if remoteGroup != nil {
            if isHiddenGroup {
                title = "Restore"
            }
            else {
                title = "Hide"
            }
        }
        let index = OperationType.delete.rawValue
        if segmentActions.titleForSegment(at: index) != title {
            segmentActions.setTitle(title, forSegmentAt: OperationType.delete.rawValue)
        }

        
        
        var operationType = OperationType(rawValue: segmentActions.selectedSegmentIndex)!
        if operation != nil {
            operationType = operation!
            segmentActions.selectedSegmentIndex = operation!.rawValue
        }
        
        
        switch operationType  {
        case .edit:
            
            if let editVC = setBottomController(.edit) as? ChannelSettingEditVC {
                editVC.refresh()
            }
            
        case .add: //Add
            
            if remoteGroup != nil {
                if let infoVC = setBottomController(.info) as? ChannelSettingInfoVC {
                    infoVC.infoLabel.text = "You cann't modify elements located inside remote group:\(remoteGroup!.name)"
                }
            }
            else {
                if let addVC = setBottomController(.add) as? ChannelSettingAddVC {
                   addVC.refresh()
                }
            }
            
        case .delete:
            if  let name = dirElement?.name,
                let _ = ChannelManager.reservedNames.index(of:name),
                let infoVC = setBottomController(.info) as? ChannelSettingInfoVC
            {
                infoVC.infoLabel.text = "You cann't modify reserved group:\(name)"
                return
            }
            
            if remoteGroup != nil {
                if let hideVC = setBottomController(.hide) as? ChannelSettingHideVC {
                    hideVC.refresh()
                }
            }
            else {
                if let delVC = setBottomController(.delete) as? ChannelSettingDeleteVC {
                    delVC.refresh()
                }
            }
            
        case .copyMove:
            
            if  let name = dirElement?.name,
                let _ = ChannelManager.reservedNames.index(of:name),
                let infoVC = setBottomController(.info) as? ChannelSettingInfoVC
            {
                infoVC.infoLabel.text = "You cann't copy/move reserved group:\(name)"
                return
            }

            
            if let copyVC = setBottomController(.copy) as? ChannelSettingCopyVC {
                copyVC.refresh()
            }
            
        case .reorder:
            
            if let orderVC = setBottomController(.reorder) as? ChannelSettingReorderVC {
                orderVC.refresh()
            }
        
        case .preview:
        
            if let previewVC = setBottomController(.preview) as? ChannelSettingPreviewVC {
                previewVC.refresh()
            }
        }
    }
    

    
    override func viewDidLoad() {
        
        channelPickerVC = ChannelPickerVC.insertToView(parentController: self, parentView: channelPickerView)
        channelPickerVC.showHiddenGroup = true
        channelPickerVC.delegate = self
        channelPickerVC.setupPath([])

        
        
        addNavigationTitle("Channels")
        
        //initialize bottom controllers
        let settingsStoryboard = UIStoryboard(name: "Settings", bundle: Bundle.main)
        for name in ChannelSettingsVC.controllerList {
            if let controller = settingsStoryboard.instantiateViewController(withIdentifier: name) as? BottomController {
                controller.view.translatesAutoresizingMaskIntoConstraints = false
                controller.channelSettingVC = self
                bottomControllers.append(controller)
            }
        }
        
        
        //set bottom controller
        currentBottomController = bottomControllers[ControllerType.info.rawValue]
        
        self.bottomView.addSubviewWithSomeSize(currentBottomController.view)
        if let infoVC = currentBottomController as? ChannelSettingInfoVC {
            infoVC.infoLabel.text = "Please, select group/channel"
        }
        
        super.viewDidLoad()
    }

    override func viewDidLayoutSubviews() {
        
    }

    
    func setBottomController(_ controllerType: ControllerType) -> BottomController {
        let controller = bottomControllers[controllerType.rawValue]
        if currentBottomController != controller {
        //self.bottomView.addSubviewWithSomeSize(newBottomController.view)
            cycleController(oldViewController: currentBottomController, toViewController: controller)
        }
        
        return controller
    }
    
        
    
    func cycleController(oldViewController: BottomController, toViewController newViewController: BottomController) {
        oldViewController.willMove(toParentViewController: nil)
        self.addChildViewController(newViewController)
        bottomView.addSubviewWithSomeSize(newViewController.view)
        //print( "addSubviews bottomView.subviews.count = \(bottomView.subviews.count)")
        newViewController.view.alpha = 0
        newViewController.view.layoutIfNeeded()
        UIView.animate(withDuration: 0.1,
            animations: {
                newViewController.view.alpha = 1
                oldViewController.view.alpha = 0
            },
            completion: { finished in
                oldViewController.view.removeFromSuperview()
                //print( "removeFromSuperview bottomView.subviews.count = \(self.bottomView.subviews.count)")
                oldViewController.removeFromParentViewController()
                newViewController.didMove(toParentViewController: self)
                self.currentBottomController = newViewController
            }
        )
    }
    
    
    func setEditController(mode:ChannelSettingEditVC.EditMode) {
        if let editVC = setBottomController(.edit) as? ChannelSettingEditVC {
            editVC.mode = mode
            editVC.refresh()
        }
    }
    
    func reloadPath(_ path: [String], isFocused:Bool = true) {
        channelPickerVC.setupPath(path)
        if isFocused {
            self.viewToFocus = channelPickerVC.collectionView
        }
        else {
            
        }
    }
    
    func prevNextName() -> (prev:String?, next:String?) {
        guard  isFocusedPath,
                let parentGroup = ChannelManager.findParentGroup(currentPath)
        else {
            return (nil, nil)
        }
        let ind = parentGroup.findDirIndex(dirElement!.name)
        if ind < 0 {
            return (nil, nil)
        }
        let prevElem = parentGroup.findDirElement(index: ind-1)
        let nextElem = parentGroup.findDirElement(index: ind+1)
        return (prevElem?.name, nextElem?.name)
    }
    
    func nextPath() -> [String] { //for move and delete: get path prev element, if first then next element
        
        var path = Array(currentPath[0..<currentPath.count-1])
        let prevNextName = self.prevNextName()
        if prevNextName.next != nil {
            path.append(prevNextName.next!)
        }
        else if prevNextName.prev != nil{
            path.append(prevNextName.prev!)
        }        
        return path
    }
    
}

extension ChannelSettingsVC : ChannelPickerDelegate {
    
    func focusedPath(chooseControl: ChannelPickerVC,  path:[String]) {
        print("ChannelSettingsVC.focusedPath \(path.joined(separator:"->"))")
        currentPath = path
        dirElement = ChannelManager.findDirElement(path)
        isFocusedPath = true
        changePath()
    }
    
    func changePath(chooseControl: ChannelPickerVC,  path:[String]) {
        print("ChannelSettingsVC.changePath \(path.joined(separator:"->"))")
        dirElement = ChannelManager.findDirElement(path)
        if case let .group(groupInfo) = dirElement! {
            if groupInfo.countDirElements() == 0 {
                currentPath = path
                isFocusedPath = false
                changePath()
            }
        }
        
    }
    
    func changePath() {
        remoteGroup = ChannelManager.findParentRemoteGroup(currentPath)
        isHiddenGroup = currentPath.index(of:ChannelManager.groupNameHidden) != nil
        setBottomPanel()

    }
    
}

