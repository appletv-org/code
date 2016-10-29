//
//  ChannelsVC.swift
//  iptv
//
//  Created by Александр Колганов on 16.09.16.
//  Copyright © 2016 Home. All rights reserved.
//

import UIKit
import AVKit

class ProgramCollectionCell : UICollectionViewCell {
    
    static let programCellId = "ProgramCell"
    
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var progressView: UIProgressView!
    
    
}

class ProgramView : UITabBar, UICollectionViewDataSource, UICollectionViewDelegate {
    
    
    var programs : [EpgProgram] = []
    var timerHideProgram : Timer?
    
    weak var dayLabel: UILabel!
    weak var programCollectionView: UICollectionView! {
        didSet {
           programCollectionView.dataSource = self
           programCollectionView.delegate = self
        }
    }

    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        super.didUpdateFocus(in: context, with: coordinator)
        
        guard let nextView = context.nextFocusedItem as? UIView,
              let prevView = context.previouslyFocusedItem as? UIView
        else {
            return
        }
        
        if nextView.isDescendant(of: self) &&  !prevView.isDescendant(of: self) {
            self.show(animated:true)
        }
        else if(!nextView.isDescendant(of: self) &&  prevView.isDescendant(of: self)) {
            self.hide(animated:true)
        }
       

        
    }
    
    func show(animated: Bool = true, _ isShow: Bool = true) {
        cancelTimer()
        var y = self.superview!.frame.size.height
        if isShow {
            y -= self.frame.size.height
        }
        
        if(animated) {
            UIView.animate(withDuration: 0.3, animations: {
                self.frame.origin.y = y
            })
        }
        else {
            self.frame.origin.y = y
        }
    }
    
    func hide(animated: Bool = true) {
        cancelTimer()
        show(animated:animated, false)
    }
    
    func isHide() -> Bool {
        return (self.frame.origin.y == self.superview!.frame.size.height)
    }
    
    func cancelTimer() {
        if(timerHideProgram != nil) {
            timerHideProgram!.invalidate()
            timerHideProgram = nil
        }
        
    }
    
    func hideAfterTime(_ time : TimeInterval = 2.0)  { //time in seconds
        cancelTimer()
        timerHideProgram = Timer.scheduledTimer(withTimeInterval: time, repeats: false, block: { (timer) in
            self.hide()
            self.timerHideProgram = nil
        })
    }
    
    func showWhenHide()  { //time in seconds
        show(animated: false)
        hideAfterTime()
    }
    
    func update(_ channel:ChannelInfo) {
        let allPrograms = ProgramManager.instance.getPrograms(forChannel:channel.name)
        //rest only today +- 1 day programs
        
        
        let beginDay = NSCalendar.current.startOfDay(for: Date())
        let minData = beginDay.addingTimeInterval(-24*60*60)
        let maxData = beginDay.addingTimeInterval(24*60*60)
        
        programs = [EpgProgram]()
        for program in allPrograms {
            if let startDate = program.start as? Date {
                if startDate >= minData && startDate < maxData {
                    programs.append(program)
                }
            }
        }
        
        //sort programs
        programs.sort(by: { $0.start!.timeIntervalSince1970 < $1.start!.timeIntervalSince1970 })
        
        print("ChannelVC::play for channel:\(channel.name) find programs:\(programs.count)" )
        programCollectionView.reloadData()
        
        //scroll to now element
        var ind = -1
        for i in 0 ..< programs.count {
            guard let startDate = programs[i].start as? Date , startDate <= Date(),
                let endDate = programs[i].stop as? Date , endDate > Date()
                else {
                    continue
            }
            ind = i
            break
        }
        if ind >= 0 {
            programCollectionView.scrollToItem(at: IndexPath(row:ind, section:0), at: .left, animated: false)
        }
        labelDayUpdate()
    }
    
    func labelDayUpdate() {
        
        let dayinSec = TimeInterval(24.0*60*60)
        var text = "Program not found"
        
        var currentDate : Date?
        
        if programs.count > 0 {
            currentDate = Date()
        }
        let visibleIndexPaths = programCollectionView.indexPathsForVisibleItems
        if visibleIndexPaths.count > 0 {
            let indexPath = visibleIndexPaths[0]
            if (indexPath.row < programs.count) {
                if let date = programs[indexPath.row].start as? Date {
                    currentDate = date
                }
            }
        }
        
        if let date = currentDate {
            text = ""
            let beginDay = NSCalendar.current.startOfDay(for: Date())
            
            let interval = date.timeIntervalSince(beginDay)
            if(interval > 0) {
                if(interval <= dayinSec) {
                    text = "Today "
                }
                else if(interval > dayinSec && interval < dayinSec*2) {
                    text = "Tommorow "
                }
            }
            else {
                if interval > -dayinSec {
                    text = "Yestarday "
                }
            }
            let formatter = DateFormatter()
            formatter.dateFormat = "dd.MM"
            text += formatter.string(from: date)
        }
        dayLabel.text = text

    }
    
    
    func setProgramText(_ program:EpgProgram, color:UIColor = UIColor.darkGray) -> NSAttributedString {
        
        struct Attributes {
            
            static let titleFont = UIFont.boldSystemFont(ofSize: 36)
            static let descFont = UIFont.systemFont(ofSize: 36)
            
            static let timeFormat : [String : Any]  = [ NSFontAttributeName: titleFont ]
            
            static let title : [String : Any] = [ NSFontAttributeName: titleFont ]
            static let desc : [String : Any] = [ NSFontAttributeName: descFont]
            
            
            static func timeString(_ date:Date) -> String {
                let formatter = DateFormatter()
                formatter.dateFormat = "HH:mm"
                return formatter.string(from: date)
            }
            
        }
        
        //start date
        
        
        let attributedText = NSMutableAttributedString()
        
        
        //time
        if let startDate = program.start as? Date {
            
            let timeString = Attributes.timeString(startDate) + " "
            attributedText.append(NSAttributedString( string: timeString, attributes: Attributes.timeFormat + [NSForegroundColorAttributeName: color] ))
        }
        
        //title
        if let title = program.title {
            attributedText.append(NSAttributedString( string: title, attributes: Attributes.title + [NSForegroundColorAttributeName: color] ))
        }
        
        //desc
        if let desc = program.desc {
            attributedText.append(NSAttributedString( string: desc, attributes: Attributes.desc + [NSForegroundColorAttributeName: color]))
        }
        
        return attributedText
        
    }
    
    //collectionView delegate
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return programs.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let index = indexPath.row
        
        let cell = self.programCollectionView.dequeueReusableCell(withReuseIdentifier: ProgramCollectionCell.programCellId, for: indexPath) as! ProgramCollectionCell
        
        if index < programs.count {
            let program = programs[index]
            cell.textView.attributedText = setProgramText(program)
            //cell.textView.text = program.title
        }
        else {
            cell.textView.text = ""
        }
        return cell
        
    }
}



class ChannelsVC : UIViewController {

    var groupInfo : GroupInfo = ChannelManager.root
    var path: [String] = [ChannelManager.root.name]
    var currentItem : DirElement?
    var focusedItem : UIFocusItem?
    var currentChannelIndex: Int = 0
    
 
    @IBOutlet weak var mainPlayer: PlayerView!

    //choose channel view contor
    @IBOutlet weak var controlView: UIView!
    @IBOutlet weak var directoryStack: DirectoryStack!
    @IBOutlet weak var focusedDirectoryStack: FocusedView!
    @IBOutlet weak var channelsView: UICollectionView!
    @IBOutlet weak var controlChannelButton: UIButton!
    @IBAction func channelAction(_ sender: AnyObject) {
        controlView.isHidden = true
    }
    
    //view for next/prev programs
    @IBOutlet weak var changeProgramView: ContainerFocused!
    @IBOutlet weak var middleChannelView: FocusedView!
    @IBOutlet weak var prevChannelView: FocusedView!
    @IBOutlet weak var nextChannelView: FocusedView!
    
    
    //show program
    @IBOutlet weak var programView: ProgramView!
    @IBOutlet weak var dayLabel: UILabel!
    @IBOutlet weak var programCollectionView: UICollectionView!

    
    //loading view
    @IBOutlet weak var loadingView: UIView!
    @IBOutlet weak var loadingChannelLabel: UILabel!
    @IBOutlet weak var loadingActivity: UIActivityIndicatorView!
    @IBOutlet weak var loadingErrorLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        
        if var currentChannelPath = UserDefaults.standard.array(forKey: "currentChannel") as? [String]  {
            let nameChannel = currentChannelPath.popLast()
            if let findGroupInfo = ChannelManager.findGroup(currentChannelPath) {
                groupInfo = findGroupInfo
                path = currentChannelPath
                for i in 0..<findGroupInfo.channels.count {
                    if findGroupInfo.channels[i].name == nameChannel {
                        currentChannelIndex = i
                        break
                    }
                }
                
            }
            
        }
        
        
        //choose channels
        channelsView.delegate = self
        channelsView.dataSource = self
        channelsView.remembersLastFocusedIndexPath = true
        
        directoryStack.delegate = self
        directoryStack.path = self.path
        
        focusedDirectoryStack.focusedFunc = { () -> [UIFocusEnvironment]? in
            if ((self.focusedItem as? ChannelCell) != nil) {
                let stackSubViews = self.directoryStack.arrangedSubviews
                if(stackSubViews.count >= 3) {
                    return [stackSubViews[stackSubViews.count-3]]
                }
            }
            return [self.channelsView]
        }

        
        //show programs
        programView.programCollectionView = programCollectionView
        programView.dayLabel = dayLabel
        
        
        controlView.isHidden = true
        
        
        mainPlayer.backgroundColor = UIColor.black
        mainPlayer.fillMode = .resize
        mainPlayer.delegate = self
        
        mainPlayer.layer.borderWidth = 10
        mainPlayer.layer.borderColor = UIColor.clear.cgColor
        
        //start play last playing channel
        if currentChannelIndex < groupInfo.channels.count {
            /*
            let channel = groupInfo.channels[currentChannelIndex]
            
            //play video
            mainPlayer.url = URL(string: channel.url)
            mainPlayer.play()
             */
            self.play(self.groupInfo.channels[self.currentChannelIndex])
            
        }

        
        //next /previous channel
        
        prevChannelView.focusedFunc = { () -> [UIFocusEnvironment]? in
            if(self.groupInfo.channels.count > 1) {
                self.currentChannelIndex -= 1
                if self.currentChannelIndex < 0 {
                    self.currentChannelIndex = self.groupInfo.channels.count - 1
                }
                self.play(self.groupInfo.channels[self.currentChannelIndex])
            }
 
            return [self.middleChannelView];
        }
        
        nextChannelView.focusedFunc = { () -> [UIFocusEnvironment]? in
            if(self.groupInfo.channels.count > 1) {
                self.currentChannelIndex += 1
                if self.currentChannelIndex >=  self.groupInfo.channels.count {
                    self.currentChannelIndex = 0
                }
                self.play(self.groupInfo.channels[self.currentChannelIndex])
            }
            return [self.middleChannelView];
        }
         
 
        // Add tap gesture recognizer to show/hide choose channels
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(sender:)))
        middleChannelView.addGestureRecognizer(tapGesture)
        
        
        //save current channel
        NotificationCenter.default.addObserver(forName: NSNotification.Name.UIApplicationDidEnterBackground, object: nil, queue: nil) { (_) in
            if self.currentChannelIndex < self.groupInfo.channels.count {
                let channelPath = self.path + [self.groupInfo.channels[self.currentChannelIndex].name]
                UserDefaults.standard.set(channelPath, forKey: "currentChannel")
            }
        }
    }


    var viewToFocus: UIView? = nil {
        didSet {
            if viewToFocus != nil {
                self.setNeedsFocusUpdate()
                self.updateFocusIfNeeded()
            }
        }
    }
    
    override var preferredFocusEnvironments: [UIFocusEnvironment] {
        if viewToFocus != nil {
            return [viewToFocus!]
        } else {
            return super.preferredFocusEnvironments
        }
    }
    
    
    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        super.didUpdateFocus(in: context, with: coordinator)
        //let nextFocusedItem = context.nextFocusedItem
        focusedItem = context.nextFocusedItem
        let nextFocusedView = context.nextFocusedItem as? UIView
        let prevFocusedView = context.previouslyFocusedItem as? UIView
        
        if  nextFocusedView != nil {
            
            //change channel cell
            
            if let cellItem = nextFocusedView as? ChannelCell {
                currentItem = cellItem.element
                return
            }
            
            //border animation for main view
            
            if nextFocusedView == middleChannelView && prevFocusedView != middleChannelView {
                
                let borderColorAnim = CABasicAnimation(keyPath: "borderColor")
                borderColorAnim.fromValue=UIColor.blue.cgColor
                borderColorAnim.toValue=UIColor.clear.cgColor
                borderColorAnim.duration = 0.5
                mainPlayer.layer.add(borderColorAnim, forKey: "borderColor")
                return
            }
            
            
        }
        
    }
    
    
    
    func play(_ channel:ChannelInfo) {
        controlView.isHidden = true
        
        //loading channel
        loadingView.isHidden = false
        loadingErrorLabel.isHidden = true
        loadingChannelLabel.text = channel.name
        
        
        mainPlayer.resetPlayer()
        mainPlayer.url = URL(string:channel.url)
        mainPlayer.play()
        
        programView.update(channel)
        programView.showWhenHide()
        
     }

    
    func channelName() -> String {
        if(currentChannelIndex < groupInfo.channels.count ) {
            return groupInfo.channels[currentChannelIndex].name
        }
        else {
            return "Name undefined"
        }
    }

    // this method is called when a tap is recognized
    func handleTap(sender: UITapGestureRecognizer) {
        if controlView.isHidden {
            controlView.isHidden = false
            viewToFocus = channelsView
        }
        else {
            controlView.isHidden = true
            viewToFocus = middleChannelView
        }
    }
    



    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension ChannelsVC: UICollectionViewDataSource {
    //---- UICollectionViewDataSource ------
    
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return  groupInfo.groups.count + groupInfo.channels.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        var index = indexPath.row
        
        let cell = self.channelsView.dequeueReusableCell(withReuseIdentifier: ChannelCell.reuseIdentifier, for: indexPath) as! ChannelCell

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
}

extension ChannelsVC: UICollectionViewDelegate {
    //---- UICollectionViewDelegate ------
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        let index = indexPath.row
        
        if(collectionView == channelsView) {
            if index < groupInfo.groups.count {
                var newPath = path.map({$0})
                newPath.append(groupInfo.groups[index].name)
                changePath(newPath)
                directoryStack.path = newPath
                return
            }
            
            currentChannelIndex = index - groupInfo.groups.count
            play(groupInfo.channels[currentChannelIndex])
        }
    }

}

extension ChannelsVC: DirectoryStackProtocol {
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
    
}

extension ChannelsVC: PlayerViewDelegate {
    
    
    //playerView Delegate
    func playerVideo(player: PlayerView, statusItemPlayer: PVItemStatus, error: Error?) {
        
        if(error != nil) {
            //loading channel
            loadingErrorLabel.isHidden = false
            loadingActivity.isHidden = true
            print("statusPlayer error: \(error)")
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
}

extension ChannelsVC { //program show
    
    
    
    
    
}

