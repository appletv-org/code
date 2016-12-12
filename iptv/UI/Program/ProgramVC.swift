//
//  ProgramVC.swift
//  iptv
//
//  Created by Александр Колганов on 16.09.16.
//  Copyright © 2016 Home. All rights reserved.
//

import UIKit


class ProgramFocusedCell : UIView {
    
    
    static let backColor = UIColor.white
    static let textColor = UIColor.black
    static let focusedBackColor = UIColor.yellow
    static let focusedTextColor = UIColor.black
    
    let label = UILabel()
    
    
    var program :EpgProgram? {
        didSet {
            if(program != nil) {
                let startStop = ProgramManager.startStopTime(program!)
                label.text = "\(startStop.start!.toFormatString("HH:mm")). \(program!.title ?? "")"
            }
            else {
                label.text = "Program guide not found"
            }
        }
    }
    
    override var canBecomeFocused : Bool {
        get {
            return true
        }
    }

    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setProperties()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setProperties()
    }
    
    
    
    
    func setProperties() {
        
        label.frame = CGRect(origin: CGPoint.zero, size: self.frame.size)
        label.backgroundColor = ProgramFocusedCell.backColor
        label.textColor = ProgramFocusedCell.textColor
        label.font = UIFont.systemFont(ofSize: 24)
        label.numberOfLines = 2
        label.textAlignment = .center
        addSubview(label)
    }
    
    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {

        coordinator.addCoordinatedAnimations(
            {
                if self.isFocused
                {
                    self.label.backgroundColor = ProgramFocusedCell.focusedBackColor
                    self.label.textColor = ProgramFocusedCell.focusedTextColor
                    
                    UIView.animate(withDuration: 0.2, animations: {
                        self.transform = CGAffineTransform(scaleX: 1.05, y: 1.2)
                    },
                    completion: {
                        finished in
                        UIView.animate(withDuration: 0.2, animations:{
                            self.transform = .identity
                        },
                        completion: nil)
                    })
                }
                else
                {
                    self.label.backgroundColor = ProgramFocusedCell.backColor
                    self.label.textColor = ProgramFocusedCell.textColor
                }
        },
        completion: nil)
    }
    
}

class ChannelFocusedCell : UIView {
    
    let imageView = UIImageView()
    let label = UILabel()
    
    override var canBecomeFocused : Bool {
        get {
            return true
        }
    }
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setSubViews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setSubViews()
    }
    
    func setSubViews() {
        imageView.frame = CGRect(origin: CGPoint.zero, size: self.frame.size)
        imageView.image = UIImage(named: "channel")
        self.addSubview(imageView)
        var labelFrame = CGRect()
        labelFrame.origin.x = self.frame.size.width / 15.0
        labelFrame.origin.y = self.frame.size.height / 7.0
        labelFrame.size.width = self.frame.size.width * 0.87
        labelFrame.size.height = self.frame.size.height * 0.6
        label.frame = labelFrame
        label.backgroundColor = UIColor.clear
        label.font = UIFont.systemFont(ofSize: 20)
        label.textColor = UIColor.black
        label.numberOfLines = 2
        label.textAlignment = .center
        self.addSubview(label)
        

    }
    
    func setChannel(_ channel:ChannelInfo) {
        label.text = channel.name
        ProgramManager.instance.getIcon(channel: channel.name, completion: { (data) in
            if data != nil {
                if let image = UIImage(data: data!) {
                    self.imageView.image = image
                    self.label.text = ""
                }
            }
        })

        
    }
    
    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        
        coordinator.addCoordinatedAnimations(
            {
                if self.isFocused
                {
                    
                    UIView.animate(withDuration: 0.2, animations: {
                        self.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
                    },
                                   completion: {
                                    finished in
                                    UIView.animate(withDuration: 0.2, animations:{
                                        self.transform = .identity
                                    },
                                                   completion: nil)
                    })
                }
                else
                {
                }
        },
            completion: nil)
    }

    
}



class ProgramVC: FocusedViewController {
    
    static let pixelInHour = CGFloat(300.0)
    static let pixelInSecond : CGFloat = (ProgramVC.pixelInHour / (60 * 60))
    static let heightElement = CGFloat(100.0)
    static let shiftHeight = CGFloat(10.0)
    static let shiftWidth = CGFloat(10.0)
    static let dayShift = 30*60 //before and after today day
    
    static let widthDayView :CGFloat = CGFloat(24*60*60 + ProgramVC.dayShift*2) * ProgramVC.pixelInSecond
    
    var channels = [ChannelInfo]()
    
    
    @IBOutlet weak var leftScrollView: UIScrollView!
    @IBOutlet weak var topScrollView: UIScrollView!
    @IBOutlet weak var mainScrollView: UIScrollView!
    
    var mainView : UIView!
    var leftView : UIView!
    var topView  : UIView!
    
    var focusedScrollView : UIScrollView?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
    }
    
    override func viewDidLayoutSubviews() {
        
        if let groupAll = ChannelManager.findGroup(["All"]) {
            channels = groupAll.channels
        }
        print("channels:\(channels.count)")
        
        
        mainView = UIView(frame: CGRect(origin: .zero, size: mainScrollView.frame.size)) //we change mainView frame later
        mainView.backgroundColor = UIColor.lightGray
        mainScrollView.addSubview(mainView)
        mainScrollView.delegate = self
        
        
        leftView = UIView(frame: CGRect(origin: .zero, size: leftScrollView.frame.size) ) //we change leftView frame later
        leftView.backgroundColor = UIColor.lightGray
        leftScrollView.addSubview(leftView)
        leftScrollView.delegate = self
        
        //topview with scale
        let topViewSize = CGSize(width: ProgramVC.widthDayView, height:topScrollView.frame.size.height)
        topView = UIView(frame: CGRect(origin: .zero, size: topViewSize ) )
        topView.backgroundColor = UIColor.lightGray
        
        var x = CGFloat(0.0)
        let hourLabelSize = CGSize(width: ProgramVC.pixelInHour, height: topView.frame.size.height)
        for i in 0...24 {
            let label = UILabel(frame:CGRect(origin:CGPoint(x:x, y:0), size:hourLabelSize))
            label.font = UIFont.systemFont(ofSize: 24)
            label.textAlignment = .center
            label.backgroundColor = UIColor.clear
            label.textColor = UIColor.black
            label.text = String(format:"%02d:%02d", i, 0)
            topView.addSubview(label)
            x += ProgramVC.pixelInHour
        }
        
        topScrollView.addSubview(topView)
        topScrollView.contentSize = topViewSize
        topScrollView.contentOffset = CGPoint.zero
        
        


        
        mainScrollView.addSubview(mainView)
        mainScrollView.contentSize = mainView.frame.size
        mainScrollView.setContentOffset(CGPoint.zero, animated: false)
        DispatchQueue.global().async {
            self.viewsUpdate()
        }
        
        //top scale -00:30 00:30
        
        
    }
    
    
    func viewsUpdate() {

        let heightView = (ProgramVC.heightElement + ProgramVC.shiftHeight) * CGFloat(channels.count)
        let mainViewSize = CGSize(width:ProgramVC.widthDayView, height: heightView)
        let leftViewSize = CGSize(width:leftScrollView.frame.size.width, height: heightView)


        DispatchQueue.main.async {
            self.mainView.subviews.forEach({ $0.removeFromSuperview() }) //remove all subviews
            self.mainView.frame = CGRect(origin:CGPoint.zero, size: mainViewSize)
            self.mainScrollView.contentSize =  mainViewSize
            
            self.leftView.subviews.forEach({ $0.removeFromSuperview() }) //remove all subviews
            self.leftView.frame = CGRect(origin:CGPoint.zero, size: leftViewSize)
            self.leftScrollView.contentSize =  leftViewSize
            
        }
        
        //fill program
        let startTime = NSCalendar.current.startOfDay(for: Date())
        let stopTime = startTime.addingTimeInterval(24*60*60)
        var y = ProgramVC.shiftHeight/2
        
        let startScaleTime = startTime.addingTimeInterval(-30*60)
        let stopScaleTime  = stopTime.addingTimeInterval(30*60)
        
        
        for channel in channels {
            
            let programs = ProgramManager.instance.getPrograms(channel: channel.name, from:startTime, to:stopTime )
            
            //fill main view
            if programs.count == 0 {
                let frame = CGRect(x: 100.0, y: y, width: mainScrollView.frame.size.width - 200.0, height: ProgramVC.heightElement)
                DispatchQueue.main.async {
                    let programCell = ProgramFocusedCell(frame: frame)
                    programCell.program = nil
                    self.mainView.addSubview(programCell)
                }
            }
            else {
                for program in programs {
                    let startStop = ProgramManager.startStopTime(program)
                    guard var start = startStop.start,
                          var stop = startStop.stop
                    else {
                        continue
                    }
                    
                    if start < startScaleTime {
                        start = startScaleTime
                    }
                    if stop > stopScaleTime {
                        stop = stopScaleTime
                    }
                    
                    let timeShift = start.timeIntervalSince(startScaleTime)
                    let x = CGFloat(timeShift) * ProgramVC.pixelInSecond + ProgramVC.shiftWidth/2
                    let timeWidth = stop.timeIntervalSince(start)
                    let width = CGFloat(timeWidth) * ProgramVC.pixelInSecond - ProgramVC.shiftWidth
                    let frame = CGRect(x: x, y: y, width: width, height: ProgramVC.heightElement)
                    DispatchQueue.main.async {
                        let programCell = ProgramFocusedCell(frame: frame)
                        programCell.program = program
                        self.mainView.addSubview(programCell)
                    }
                }
            }
            
            //fill left view
            let channelFrame = CGRect(x:ProgramVC.shiftWidth, y:y, width: ProgramVC.heightElement * 1.2, height: ProgramVC.heightElement)
            DispatchQueue.main.async {
                let channelView = ChannelFocusedCell(frame: channelFrame)
                channelView.setChannel(channel)
                self.leftView.addSubview(channelView)
            }
            
            y += ProgramVC.shiftHeight + ProgramVC.heightElement
        }
        
    }
    
    
    
    override func shouldUpdateFocus(in context: UIFocusUpdateContext) -> Bool {
        focusedScrollView = nil
        if let _ = context.nextFocusedItem as? ProgramFocusedCell {
            focusedScrollView = mainScrollView
        }
        else if let _ = context.nextFocusedItem as? ChannelFocusedCell {
            focusedScrollView = leftScrollView
        }
        return true

    }


}

extension ProgramVC :  UIScrollViewDelegate {

    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {// any offset changes
        if(scrollView == mainScrollView && focusedScrollView == mainScrollView) {
            topScrollView.setContentOffset(CGPoint(x:mainScrollView.contentOffset.x, y:0), animated: false)
            leftScrollView.setContentOffset(CGPoint(x:0, y:mainScrollView.contentOffset.y), animated: false)
        }
        
        else if(scrollView == leftScrollView && focusedScrollView == leftScrollView) {
            
            mainScrollView.setContentOffset(CGPoint(x:mainScrollView.contentOffset.x, y:leftScrollView.contentOffset.y), animated: false)
        }
        
        
    }

}

