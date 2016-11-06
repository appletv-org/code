//
//  ChannelsVC.swift
//  iptv
//
//  Created by Александр Колганов on 16.09.16.
//  Copyright © 2016 Home. All rights reserved.
//

import UIKit
import AVKit


class PipView : PlayerView {
    
}

class ProgramCollectionCell : UICollectionViewCell {
    
    static let programCellId = "ProgramCell"
    
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var progressView: UIProgressView!
    
    func setProgram(_ program:EpgProgram?) {
        if program != nil {
            self.textView.attributedText = setProgramText(program!)
        }
        else {
            self.textView.text = "The program guide is not available"
        }
    }
    
    func setProgramText(_ program:EpgProgram) -> NSAttributedString {
        
        struct Attributes {
            
            static let titleFont = UIFont.boldSystemFont(ofSize: 36)
            static let descFont = UIFont.systemFont(ofSize: 36)
            
            static let timeFormat : [String : Any]  = [ NSFontAttributeName: titleFont, NSForegroundColorAttributeName: UIColor.darkGray ]
            
            static let title : [String : Any] = [ NSFontAttributeName: titleFont, NSForegroundColorAttributeName: UIColor.darkGray ]
            static let desc : [String : Any] = [ NSFontAttributeName: descFont, NSForegroundColorAttributeName: UIColor.darkGray]
            
            
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
            attributedText.append(NSAttributedString( string: timeString, attributes: Attributes.timeFormat))
        }
        
        //title
        if let title = program.title {
            attributedText.append(NSAttributedString( string: title + "\n", attributes: Attributes.title  ))
        }
        
        //desc
        if let desc = program.desc {
            attributedText.append(NSAttributedString( string: desc, attributes: Attributes.desc ))
        }
        
        return attributedText
        
    }
    
    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        super.didUpdateFocus(in: context, with: coordinator)
        
        if context.nextFocusedItem as? ProgramCollectionCell == self {
            if let attrText = self.textView.attributedText {
                let attrString = NSMutableAttributedString(attributedString: attrText)
                attrString.addAttribute(NSForegroundColorAttributeName, value: UIColor.white, range:NSMakeRange(0, attrText.length))
                self.textView.attributedText = attrString
            }
            self.textView.layer.borderWidth = 5.0
            self.textView.layer.borderColor = UIColor.white.cgColor
        }
        
        if context.previouslyFocusedItem as? ProgramCollectionCell == self {
            if let attrText = self.textView.attributedText {
                
                let attrString = NSMutableAttributedString(attributedString: attrText)
                attrString.addAttribute(NSForegroundColorAttributeName, value: UIColor.darkGray, range:NSMakeRange(0, attrText.length))
                self.textView.attributedText = attrString
                self.textView.layer.borderWidth = 0.0
                
            }
        }
    }


}

class ProgramView : ContainerFocused, UICollectionViewDataSource, UICollectionViewDelegate {
    
    var channel : ChannelInfo?
    var programs : [EpgProgram] = []
    var timerHideProgram : Timer?
    
    weak var dayLabel: UILabel!
    weak var actionButtons : UISegmentedControl!
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
        self.channel = channel
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
        
        var programDate = Date()
        
        let visibleIndexPaths = programCollectionView.indexPathsForVisibleItems
        if programs.count > 0 && visibleIndexPaths.count > 0 {
            let indexPath = visibleIndexPaths[0]
            if (indexPath.row < programs.count) {
                if let date = programs[indexPath.row].start as? Date {
                    programDate = date
                }
            }
        }
        
        
        var text = ""
        let beginDay = NSCalendar.current.startOfDay(for: Date())
        
        let interval = programDate.timeIntervalSince(beginDay)
        if(interval > 0) {
            if(interval <= dayinSec) {
                text += "Today "
            }
            else if(interval > dayinSec && interval < dayinSec*2) {
                text += "Tommorow "
            }
        }
        else {
            if interval > -dayinSec {
                text += "Yestarday "
            }
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM"
        text += formatter.string(from: programDate)
        
        if channel != nil {
            text += ": \(channel!.name)"
        }

        dayLabel.text = text

    }
    
    
    
    //collectionView delegate
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return programs.count > 0 ?  programs.count : 1
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let index = indexPath.row
        
        let cell = self.programCollectionView.dequeueReusableCell(withReuseIdentifier: ProgramCollectionCell.programCellId, for: indexPath) as! ProgramCollectionCell
        
        var program :EpgProgram? = nil
        if index < programs.count {
            program = programs[index]
        }
        cell.setProgram(program)

        return cell
        
    }
}



class ChannelsVC : UIViewController, ChannelPickerProtocol {

    weak var channelPickerVC : ChannelPickerVC?

    
    var groupInfo : GroupInfo = ChannelManager.root
    var path: [String] = [ChannelManager.root.name]
    var currentItem : DirElement?
    var focusedItem : UIFocusItem?
    var currentChannelIndex: Int = 0
    
 
    @IBOutlet weak var mainPlayer: PlayerView!

    //choose channel view contor
    @IBOutlet weak var channelPickerView: UIView!
    @IBAction func channelAction(_ sender: AnyObject) {
        channelPickerView.isHidden = true
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

    @IBOutlet weak var actionButtons: UISegmentedControl!
    
    //loading view
    @IBOutlet weak var loadingView: UIView!
    @IBOutlet weak var loadingChannelLabel: UILabel!
    @IBOutlet weak var loadingActivity: UIActivityIndicatorView!
    @IBOutlet weak var loadingErrorLabel: UILabel!
    
    override func viewDidLoad() {
        
        let mainStoryboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        channelPickerVC = mainStoryboard.instantiateViewController(withIdentifier: "ChannelPickerVC") as? ChannelPickerVC
        channelPickerVC!.view.translatesAutoresizingMaskIntoConstraints = false
        channelPickerVC!.delegate = self
        self.containerAdd(childViewController: channelPickerVC!, toView:channelPickerView)
        channelPickerVC!.delegate = self

        
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        
        loadingView.isHidden = true
        
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
        
        
        //show programs
        programView.programCollectionView = programCollectionView
        programView.dayLabel = dayLabel
        programView.actionButtons = actionButtons
        
        
        channelPickerView.isHidden = true
        
        
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
    
    
    func selectedPath(chooseControl: ChannelPickerVC,  path:[String]) {
        if let newGroupInfo = ChannelManager.findParentGroup(path) {
            if let index = newGroupInfo.channels.index(where: {$0.name == path.last}) {
                groupInfo = newGroupInfo
                currentChannelIndex  = index
                play(groupInfo.channels[index])
            }
        }
    }
    
    func play(_ channel:ChannelInfo) {
        channelPickerView.isHidden = true
        
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
        if channelPickerView.isHidden {
            channelPickerView.isHidden = false
            viewToFocus = channelPickerView
            
            if  groupInfo.channels.count < currentChannelIndex {
                channelPickerVC!.setupPath(path + [groupInfo.channels[currentChannelIndex].name])
            }

        }
        else {
            channelPickerView.isHidden = true
            viewToFocus = middleChannelView
        }
    }
 
    



    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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

