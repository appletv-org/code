
//
//  ChannelSettinsVC.swift
//  iptv
//
//  Created by Александр Колганов on 19.09.16.
//  Copyright © 2016 Home. All rights reserved.
//

import UIKit



class ChannelSettingsVC : UIViewController {
    
    
    static let controllerList = ["ChannelSettingInfoVC", "ChannelSettingEditVC", "ChannelSettingAddVC"]
    enum ControllerType : Int  {
        case info = 0, edit, add
    }
    
    enum OperationType : Int {
        case edit = 0, add, delete, copyMove, reorder
    }
    
    var bottomControllers = [UIViewController]()
    var currentBottomController : UIViewController!
    
    var currentPath = [String]()
    
    weak var channelPickerVC : ChannelPickerVC!
    

    @IBOutlet weak var channelPickerView: UIView!
    
    @IBOutlet weak var titleLabel: UILabel!
    
    
    @IBOutlet weak var segmentActions: UISegmentedControl!
    
    @IBAction func segmentActionChanged(_ sender: UISegmentedControl) {
        setBottomPanel()

        //print("change action")
    }
    
    @IBOutlet weak var bottomView: UIView!
    
    
    func setBottomPanel(operation:OperationType? = nil) {
        
        var operationType = OperationType(rawValue: segmentActions.selectedSegmentIndex)!
        if operation != nil {
            operationType = operation!
            segmentActions.selectedSegmentIndex = operation!.rawValue
        }
        
        
        var path = currentPath
        if operationType == .add && path.count > 0 {
            _ = path.popLast()
        }
        
        if let remoteGroup = ChannelManager.findParentRemoteGroup(path) {
            if let infoVC = setBottomController(.info) as? ChannelSettingInfoVC {
               infoVC.setParameters("you can not make changes into remote group: \(remoteGroup.name)")
            }
            return
        }
        
        switch operationType  {
        case .edit:
            if let editVC = setBottomController(.edit) as? ChannelSettingEditVC {
                editVC.setParameters(currentPath, mode: .edit)
            }
            
        case .add: //Add
            if let addVC = setBottomController(.add) as? ChannelSettingAddVC {
               addVC.setParameters(path)
            }
            
            
        default:
            if let infoVC = setBottomController(.info) as? ChannelSettingInfoVC {
                infoVC.setParameters("bottom control for index \(operationType.rawValue) not realize now")
            }
        }
        
        
    }
    
    
    @IBAction func delAction(_ sender: AnyObject) {
        
        if currentPath.count >= 1 { //we cannot del root group
            
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
                    channelPickerVC.setupPath(currentPath)
                }
                
                ChannelManager.save()
            }
        }
        
    }
    
    
    override func viewDidLoad() {
        
        channelPickerVC = ChannelPickerVC.insertToView(parentController: self, parentView: channelPickerView)
        channelPickerVC.delegate = self
        channelPickerVC.setupPath([])

        
        
        addNavigationTitle("Channels")
        
        //initialize bottom controllers
        let settingsStoryboard = UIStoryboard(name: "Settings", bundle: Bundle.main)
        for name in ChannelSettingsVC.controllerList {
            let controller = settingsStoryboard.instantiateViewController(withIdentifier: name)
            controller.view.translatesAutoresizingMaskIntoConstraints = false
            bottomControllers.append(controller)
        }
        
        /*
         //add bottom controllers to parent(self) controller
         for controller in bottomControllers {
         self.addChildViewController(controller)
         controller.didMove(toParentViewController: self)
         }
         */
        
        //set bottom controller
        currentBottomController = bottomControllers[ControllerType.info.rawValue]
        
        self.bottomView.addSubviewWithSomeSize(currentBottomController.view)
        if let infoVC = currentBottomController as? ChannelSettingInfoVC {
            infoVC.setParameters("Please, select group/channel")
        }
        
        super.viewDidLoad()
    }

    override func viewDidLayoutSubviews() {
        
    }

    
    func setBottomController(_ controllerType: ControllerType) -> UIViewController {
        let controller = bottomControllers[controllerType.rawValue]
        if currentBottomController != controller {
        //self.bottomView.addSubviewWithSomeSize(newBottomController.view)
            cycleController(oldViewController: currentBottomController, toViewController: controller)
        }
        
        return controller
    }
    
    func cycleControllerWithoutAutoLayout(oldViewController: UIViewController, toViewController newViewController: UIViewController) {
        self.transition(from: oldViewController, to: newViewController, duration: 0.2, options: .transitionCrossDissolve , animations: nil,
            completion:  { (complete) in
                if complete {
                    self.currentBottomController = newViewController
                    //self.bottomView.setNeedsLayout()
                }
            }
        )

    }
    
    
    func cycleController(oldViewController: UIViewController, toViewController newViewController: UIViewController) {
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
            var path = currentPath
            let _ = path.popLast()
            editVC.setParameters(path, mode: mode)
        }
    }
    
    func reloadPath(_ path: [String]) {
        channelPickerVC.setupPath(path)
    }
    
   
    /*
    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        super.didUpdateFocus(in: context, with: coordinator)
        
        if let nextFocusedItem = context.nextFocusedItem {
            //print("nextFocusedItem : \(nextFocusedItem)")
            focusedItem = nextFocusedItem
            if let cellItem = nextFocusedItem as? ChannelCell {
                currentItem = cellItem.element
                titleLabel.text = currentItem!.name
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

extension ChannelSettingsVC : ChannelPickerDelegate {
    
    func focusedPath(chooseControl: ChannelPickerVC,  path:[String]) {
        currentPath = path
        setBottomPanel()
    }
    
}

