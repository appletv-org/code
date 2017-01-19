//
//  ChannelsVC.swift
//  iptv
//
//  Created by Александр Колганов on 16.09.16.
//  Copyright © 2016 Home. All rights reserved.
//

import UIKit
import AVKit



class PipPlayer : PlayerView {
   
    var path : [String]?
    
    func setup() {
        self.backgroundColor = UIColor.black
        self.fillMode = .resize
        self.player?.isMuted = true
        
        
    }
    
    func play(_ path: [String]?) {
        self.resetPlayer()
        self.path = path
        
        if path != nil {
            if let dirElement = ChannelManager.findDirElement(path!) {
                if case let .channel(channelInfo) = dirElement {
                    self.url = URL(string:channelInfo.url)
                    self.play()
                    self.player?.volume = 0.0
                }
            }
        }
    }
    
}


class ChannelsVC : FocusedViewController {

    weak var channelPickerVC : ChannelPickerVC!

    //current channel
    var parentPath: [String] = [ChannelManager.root.name]
    var groupInfo : GroupInfo = ChannelManager.root
    var currentChannelIndex: Int = 0
    
    var currentChannelPath : [String]? {
        get {
            if currentChannelIndex < groupInfo.channels.count {
                return parentPath + [groupInfo.channels[currentChannelIndex].name]
            }
            else {
                return nil
            }
        }
    }
    
    //toolbar animation
    var timerHideProgram : Timer?
    var isProgramShow : Bool = true     //programView is show or hide
    var lastSwitchProgramTime = Date() //prevent fast switch channels
    
    //pip show/hide
    var isPipView : Bool = false

    let  imageFavoriteOn = UIImage(named: "favoriteOn")
    let  imageFavoriteOff = UIImage(named: "favoriteOff")
    
 
    @IBOutlet weak var mainPlayer: PlayerView!

    //choose channel view contor
    @IBOutlet weak var channelChooserContainer: UIView!
    @IBOutlet weak var buttonChannelClose: UIButton!
    @IBAction func buttonCloseAction(_ sender: Any) {
        channelChooserContainer.isHidden = true
        programHide(animated: true)
        self.viewToFocus = self.middleChannelView
    }
    @IBOutlet weak var channelPickerView: UIView!
    
    
    
    //view for next/prev programs
    @IBOutlet weak var changeProgramView: ContainerFocused!
    @IBOutlet weak var middleChannelView: FocusedView!
    @IBOutlet weak var prevChannelView: FocusedView!
    @IBOutlet weak var nextChannelView: FocusedView!
    
    
    //show program
    @IBOutlet weak var programAndPipView: UIView!
    @IBOutlet weak var programView: ProgramView!
    @IBOutlet weak var programCollectionView: UICollectionView!
    
    @IBOutlet weak var dayLabel: UILabel!
    @IBOutlet weak var actionButtons: UISegmentedControl!

    //constrain for show/hide program/channel
    @IBOutlet weak var programViewBottomConstraint: NSLayoutConstraint!

    //pipView
    @IBOutlet weak var pipPlayer: PipPlayer!
    
    //pipview show/hide constrains
    @IBOutlet weak var pipviewTrailingConstraint: NSLayoutConstraint!
    
    
    //loading view
    @IBOutlet weak var loadingView: UIView!
    @IBOutlet weak var loadingChannelLabel: UILabel!
    @IBOutlet weak var loadingActivity: UIActivityIndicatorView!
    @IBOutlet weak var loadingErrorLabel: UILabel!
    
    enum SegmentAction : Int {
        case favorite = 0, delete, pip
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()

        
        channelPickerVC = ChannelPickerVC.insertToView(parentController: self, parentView: channelPickerView)
        channelPickerVC.showAllGroup = true
        channelPickerVC.setupPath([])
        channelPickerVC.delegate = self
        
        loadingView.isHidden = true  // hide loading view
        
        //program guide
        programView.channelsVC = self
        
        let tapActionButton = UITapGestureRecognizer( target: self, action:  #selector(programAction))
        actionButtons.addGestureRecognizer(tapActionButton)
        

        programHide(animated: false)
        
        //hide pip view
        pipHide(animated: false)
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: InAppPurchaseManager.changeStateNotification), object: nil, queue: nil) { (notification) in
            if let product = notification.object as? InAppProduct {
                if self.isPipView {
                    if product.state == .expire {
                        self.pipHide(animated: true)
                    }
                }
                else {
                    if product.state == .tryPeriod || product.state == .bought {
                        self.pipShow(animated: true)
                    }
                }
            }
        }
        //mainPlayer
        mainPlayer.backgroundColor = UIColor.black
        mainPlayer.fillMode = .resize
        mainPlayer.delegate = self
        
        mainPlayer.layer.borderWidth = 10
        mainPlayer.layer.borderColor = UIColor.clear.cgColor
        
        //pipPlayer
        pipPlayer.setup()
        //pipPlayer.delegate = self
        
        
        
        //next /previous channel
        
        changeProgramView.focusedObject = self.middleChannelView
        
        
        let tapChannelChooser = UITapGestureRecognizer( target: self, action:  #selector(showChannelChooser))
        changeProgramView.addGestureRecognizer(tapChannelChooser)

         
        //start play last playing channel
        if      let savedPath = UserDefaults.standard.array(forKey: "currentChannel") as? [String],
                let findGroupInfo = ChannelManager.findParentGroup(savedPath),
                let index = findGroupInfo.channels.index(where: {$0.name == savedPath.last!}) {
            groupInfo = findGroupInfo
            parentPath = savedPath
            _ = parentPath.popLast()
            currentChannelIndex = index
            play(groupInfo.channels[currentChannelIndex])
            self.viewToFocus = middleChannelView
        }
        else {
            self.channelChooserContainer.isHidden = false
            self.programShow(animated:false)
            
        }
        
        //menu button hide channel chooser by menu button
        let menuRecognizer = UITapGestureRecognizer(target: self, action: #selector(menuClickHandler))
        menuRecognizer.allowedPressTypes = [NSNumber(value: UIPressType.menu.rawValue)];
        self.view.addGestureRecognizer(menuRecognizer)
        
        //play button replace pip and main url (if pip is activated)
        let playRecognize = UITapGestureRecognizer(target: self, action: #selector(playClickHandler))
        playRecognize.allowedPressTypes = [NSNumber(value: UIPressType.playPause.rawValue)];
        self.view.addGestureRecognizer(playRecognize)

        
        
        //application notification background/foreground/terminate
        NotificationCenter.default.addObserver(forName: NSNotification.Name.UIApplicationDidEnterBackground, object: nil, queue: nil) { (_) in
            self.saveCurrentChannel()
        }
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name.UIApplicationWillTerminate, object: nil, queue: nil) { (_) in
            self.saveCurrentChannel()
        }
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name.UIApplicationWillEnterForeground, object: nil, queue: nil) { (_) in
            if self.currentChannelIndex < self.groupInfo.channels.count{
                self.play(self.groupInfo.channels[self.currentChannelIndex])
            }
        }
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if  let channel = programView.channel
        {
            let _ = programView.update(channel)
        }        
    }

    
    deinit {
       NotificationCenter.default.removeObserver(self)
    }
    
    func switchProgram(_ to:Int) {
        if lastSwitchProgramTime.timeIntervalSinceNow < -0.5 {
            if(groupInfo.channels.count > 1) {
                currentChannelIndex += to
                if currentChannelIndex < 0 {
                    currentChannelIndex = groupInfo.channels.count - 1
                }
                else if currentChannelIndex >=  groupInfo.channels.count {
                    currentChannelIndex = 0
                }
                
                lastSwitchProgramTime = Date()
                play(groupInfo.channels[currentChannelIndex])
            }
        }
    }
        
        
    func programAction(sender: UITapGestureRecognizer) {
        if let tapSegment = SegmentAction(rawValue:actionButtons.selectedSegmentIndex) {
            switch(tapSegment) {
               
            case .pip:
                pipShow(animated: true, !isPipView)
            
            
            case .favorite:
                
                if currentChannelIndex < groupInfo.channels.count {
                    let channel = groupInfo.channels[currentChannelIndex]
                    ChannelManager.changeFavoriteChannel(channel)
                    let favImage = ChannelManager.favoriteIndex(channel) != nil ? imageFavoriteOn : imageFavoriteOff
                    actionButtons.setImage(favImage, forSegmentAt: 0)
                }
            
                
                
            case .delete:
                
                if currentChannelIndex < groupInfo.channels.count {
                    let channel = groupInfo.channels[currentChannelIndex]
                    simpleAlertChooser(title: "Delete channel \"\(channel.name)\"",
                                            message: "Are you sure?",
                                            buttonTitles: ["Yes", "No"],
                                            prefferButton:0,
                                            completion: { (ind) in
                        if ind == 0 {
                            let _ = ChannelManager.delPathElement(self.currentChannelPath!)
                            self.switchProgram(0)
                        }
                    })
                    
                }
            }
            
        }
    }
    
    

    
    func saveCurrentChannel() {
        if self.currentChannelIndex < self.groupInfo.channels.count {
            let channelPath = parentPath + [self.groupInfo.channels[self.currentChannelIndex].name]
            UserDefaults.standard.set(channelPath, forKey: "currentChannel")
        }
        
    }


    
    override func shouldUpdateFocus(in context: UIFocusUpdateContext) -> Bool {
        
        let nextView = context.nextFocusedItem as? UIView
        let prevView = context.previouslyFocusedItem as? UIView
        
        //prevent show tabbar by move to up
        if  nextView != nil,
            let tabBar = self.tabBarController?.tabBar,
            nextView!.isDescendant(of: tabBar)
        {
            return false
        }
        
        if  prevView == buttonChannelClose,
            nextView == middleChannelView
        {
            return false
        }
 
        return super.shouldUpdateFocus(in: context)
    }
    
    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        super.didUpdateFocus(in: context, with: coordinator)
        //let nextFocusedItem = context.nextFocusedItem
        let nextFocusedView = context.nextFocusedItem as? UIView
        let prevFocusedView = context.previouslyFocusedItem as? UIView
        
        
        //switch program to prev/next
        if prevFocusedView == middleChannelView &&
            (nextFocusedView == prevChannelView || nextFocusedView == nextChannelView)
        {
            if nextFocusedView == nextChannelView  {
                self.switchProgram(1)
            }
            else {
                self.switchProgram(-1)
            }
            
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: { 
                if(self.prevChannelView.isFocused || self.nextChannelView.isFocused) {
                    self.viewToFocus = self.middleChannelView
                }
            })
            
        }
    
        //border animation for main view
        if  nextFocusedView != nil {
            if nextFocusedView == middleChannelView && prevFocusedView != middleChannelView {
                
                let borderColorAnim = CABasicAnimation(keyPath: "borderColor")
                borderColorAnim.fromValue=UIColor.blue.cgColor
                borderColorAnim.toValue=UIColor.clear.cgColor
                borderColorAnim.duration = 0.5
                mainPlayer.layer.add(borderColorAnim, forKey: "borderColor")
            }
        }
        
        //programView show/hide
        if nextFocusedView != nil && prevFocusedView != nil {
            if nextFocusedView!.isDescendant(of: programAndPipView) &&  prevFocusedView!.isDescendant(of: changeProgramView) {
                self.programShow(animated:true)
            }
            else if nextFocusedView!.isDescendant(of: changeProgramView) &&  prevFocusedView!.isDescendant(of: programAndPipView) {
                self.programHide(animated:true)            
            }
        }
        
        
        
        /*
        //print debug focused view
        var tag = 0
        var nextView = nextFocusedView
        while(nextView != nil) {
            if(nextView!.tag != 0) {
                tag = nextView!.tag
                break
            }
            nextView = nextView!.superview
        }
        print("DidUpdateFocused to: \(tag)")
        */
    }
    
    
    
    func play(_ channel:ChannelInfo) {
        channelChooserContainer.isHidden = true
        
        //loading channel
        loadingView.isHidden = false
        loadingErrorLabel.isHidden = true
        loadingChannelLabel.text = channel.name
        
        
        mainPlayer.resetPlayer()
        mainPlayer.url = URL(string:channel.url)
        mainPlayer.play()
        
        
        //set favorite button
        let favImage = ChannelManager.favoriteIndex(channel) != nil ? imageFavoriteOn : imageFavoriteOff
        actionButtons.setImage(favImage, forSegmentAt: 0)

        
        if programView.update(channel) {
            programShow(animated: true, hideTime: 4.0)
        }
        
     }

    
    func channelName() -> String {
        if(currentChannelIndex < groupInfo.channels.count ) {
            return groupInfo.channels[currentChannelIndex].name
        }
        else {
            return "Name undefined"
        }
    }
 

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}

extension ChannelsVC : ChannelPickerDelegate {

    func focusedPath(chooseControl: ChannelPickerVC,  path:[String])    {
        if let dirElement = ChannelManager.findDirElement(path) {
            if case let .channel(channelInfo) = dirElement {
                let _ = programView.update(channelInfo)
            }
        }
    }
    
    func selectedPath(chooseControl: ChannelPickerVC,  path:[String]) {
        if let newGroupInfo = ChannelManager.findParentGroup(path) {
            var pathParent = path
            let channelName = pathParent.popLast()
            if let index = newGroupInfo.channels.index(where: {$0.name == channelName}) {
                groupInfo = newGroupInfo
                self.parentPath = pathParent
                currentChannelIndex  = index
                play(groupInfo.channels[index])
                self.viewToFocus = middleChannelView
            }
        }
    }

    //func changePath(chooseControl: ChannelPickerVC,  path:[String])     {}
    //func selectedPath(chooseControl: ChannelPickerVC,  path:[String])   {}

}

extension ChannelsVC { //programView animation
    
    func programShow(animated:Bool, hideTime: Double? = nil, _ isShow:Bool = true) {
        if isShow {
            programViewBottomConstraint.constant = 0
        }
        else {
            programViewBottomConstraint.constant = -programView.frame.size.height
        }
        
        cancelProgramHideTimer()
        isProgramShow = isShow

        if(animated) {
            UIView.animate(withDuration: 0.3, animations: {
                self.view.layoutIfNeeded()
            })
        }
        else {
            self.view.layoutIfNeeded()
        }
        
        if(isShow) {
            //self.viewToFocus = self.programCollectionView
            if hideTime != nil {
                timerHideProgram = Timer.scheduledTimer(withTimeInterval: 4.0, repeats: false, block: { (_) in
                    self.programHide(animated:true)
                })
            }
        }
        else {
            // move focus from programView
            if let focusedView = UIScreen.main.focusedView {
                if focusedView.isDescendant(of: programView)  {
                    self.viewToFocus = middleChannelView
                }
            }
        }
    }
    
    func programHide(animated:Bool) {
        programShow(animated:animated, hideTime:nil, false)
    }

    
    func cancelProgramHideTimer() {
        if(timerHideProgram != nil) {
            print("cancel hide timer")
            timerHideProgram!.invalidate()
            timerHideProgram = nil
        }
    }
    
}

extension ChannelsVC: PlayerViewDelegate {
    
    
    //playerView Delegate
    func playerVideo(player: PlayerView, statusItemPlayer: PVItemStatus, error: Error?) {
        
        if(error != nil) {
            //loading channel
            loadingErrorLabel.isHidden = false
            loadingActivity.isHidden = true
            print("AVPlayerItemStatus error: \(error)")
            return
        }
        
        switch statusItemPlayer {
        case AVPlayerItemStatus.unknown:
            print("AVPlayerItemStatus unknown")
        case AVPlayerItemStatus.readyToPlay:
            print("AVPlayerItemStatus readyToPlay")
            
            loadingErrorLabel.isHidden = true
            loadingActivity.isHidden = false
            loadingView.isHidden = true
            
        case AVPlayerItemStatus.failed:
            print("AVPlayerItemStatus failed")
        }
    }
    
    
    func playerVideo(player: PlayerView, statusPlayer: PVStatus, error: Error?) {
        print("playerVideo")
    }
    
}

extension ChannelsVC { //pip show/hide
    
    func pipShow( animated:Bool, _ isShow:Bool = true) {
        
        if isShow {
            if let pipProduct = InAppPurchaseManager.getProductById(InAppPurchaseManager.productPipId) {
                 if pipProduct.state == .noInit ||  pipProduct.state == .expire {
                    let pipPaymentVC = PIPPaymentVC.loadFromIB()
                    present(pipPaymentVC, animated: true, completion: nil)
                    return
                }
            }
            else {
                print("error: not found pip product")
            }
            
        }
        
        if isShow {
            pipviewTrailingConstraint.constant = 0
        }
        else {
            pipviewTrailingConstraint.constant = -pipPlayer.frame.size.width
        }
        programCollectionView.collectionViewLayout.invalidateLayout()
        if(animated) {
            UIView.animate(withDuration: 0.3, animations: {
                self.view.layoutIfNeeded()
            })
        }
        else {
            self.view.layoutIfNeeded()
        }
        isPipView = isShow
        
        if(isShow) {
            pipPlayer.play(self.currentChannelPath)
        }
        else {
            pipPlayer.resetPlayer()
        }
    }
    
    func pipHide(animated:Bool) {
        pipShow(animated:animated, false)
    }
    

}

extension ChannelsVC { //show/hide  channel chooser

    func showChannelChooser(sender: UITapGestureRecognizer) {
        channelChooserContainer.isHidden = false
        programShow(animated:false)
        //set position
        if currentChannelIndex < groupInfo.channels.count {
            channelPickerVC?.setupPath(parentPath + [groupInfo.channels[currentChannelIndex].name])
        }
        else {
            channelPickerVC?.setupPath(parentPath, isParent:true)
        }
        self.viewToFocus = self.channelPickerVC?.collectionView
    }
    
    func menuClickHandler(sender: UITapGestureRecognizer) {
        if self.channelChooserContainer.isHidden == false {
            self.channelChooserContainer.isHidden = true
            programHide(animated: false)
            self.viewToFocus = middleChannelView
        }
        else {
            self.viewToFocus = self.tabBarController?.tabBar
        }
    }
}

extension ChannelsVC { //replace pip and main view
    
    func playClickHandler(sender: UITapGestureRecognizer) {
        
        if !isPipView {
            return
            /*
            if mainPlayer.
            mainPlayer.stop()
             */
        }
        
        //change paths pip and main
        if          var mainPath = pipPlayer.path,
                    let findGroupInfo = ChannelManager.findParentGroup(mainPath),
                    let name = mainPath.popLast(),
                    let index = findGroupInfo.channels.index(where: {$0.name == name}),
                    let pipPath = currentChannelPath {
            groupInfo =  findGroupInfo
            parentPath = mainPath
            currentChannelIndex = index
            play(groupInfo.channels[currentChannelIndex])
            pipPlayer.play(pipPath)
        }
    }

}



