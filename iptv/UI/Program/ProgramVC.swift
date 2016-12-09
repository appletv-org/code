//
//  ProgramVC.swift
//  iptv
//
//  Created by Александр Колганов on 16.09.16.
//  Copyright © 2016 Home. All rights reserved.
//

import UIKit


class PrintPreferFocusedView : UIView {
    
    override var canBecomeFocused : Bool {
        get {
            return true
        }
    }
    
    override var preferredFocusEnvironments: [UIFocusEnvironment] {
        
        var envs = [UIFocusEnvironment]()
        for view in self.subviews {
            if view.canBecomeFocused {
                envs.append(view as UIFocusEnvironment)
            }
        }
        print("focused")
        return envs
    }
}

//
//  CustomFocusButton.swift
//

import UIKit



class ProgramFocusedCell : UIButton {
    
    
    static let backColor = UIColor.darkGray
    static let textColor = UIColor.white
    static let focusedBackColor = UIColor.white
    static let focusedTextColor = UIColor.black
    
    /*
    override var canBecomeFocused : Bool {
        get {
            return true
        }
    }
    
    override var preferredFocusEnvironments: [UIFocusEnvironment] {
        get {
            return []
        }
    }
    */

    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.titleLabel?.text = "Button"
        //self.backgroundColor = UIColor.gray
        self.backgroundColor = ProgramFocusedCell.backColor
        self.setTitleColor(ProgramFocusedCell.textColor, for: .normal)
        self.setTitleColor(ProgramFocusedCell.focusedTextColor, for: .focused)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        //self.text = "Button"
    }
    
    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {

        coordinator.addCoordinatedAnimations(
            {
                if self.isFocused
                {
                    self.backgroundColor = ProgramFocusedCell.focusedBackColor
                    
                    UIView.animate(withDuration: 0.2, animations: {
                        self.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
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
                    self.backgroundColor = ProgramFocusedCell.backColor
                }
        },
        completion: nil)
    }
    
    
}

class ProgramVC: UIViewController {
    
    static let widthHour = 200
    static let heightElement = 200
    static let shiftHeight = 10
    static let shiftWidth = 10
    
    var channels = [ChannelInfo]()
    
    
    @IBOutlet weak var leftScrollView: UIScrollView!
    @IBOutlet weak var topScrollView: UIScrollView!
    @IBOutlet weak var mainScrollView: UIScrollView!
    
    var mainView : UIView!
    var leftView : UIView!
    var topView  : UIView!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
    }
    
    override func viewDidLayoutSubviews() {
        
        if let groupAll = ChannelManager.findGroup(["All"]) {
            channels = groupAll.channels
        }
        
        mainView = UIView(frame: mainScrollView.frame )
        mainView.backgroundColor = UIColor.lightGray
        self.mainScrollView.addSubview(mainView)
        
        leftView = UIView(frame: leftScrollView.frame )
        leftView.backgroundColor = UIColor.lightGray
        leftScrollView.addSubview(leftView)
        
        mainScrollView.addSubview(mainView)
        mainScrollView.contentSize = mainView.frame.size
        mainScrollView.setContentOffset(CGPoint.zero, animated: false)
        mainViewUpdate()
        
    }
    
    func mainViewUpdate() {
        
        mainView.subviews.forEach({ $0.removeFromSuperview() }) //remove all subviews

        
        let heightView = (ProgramVC.heightElement + ProgramVC.shiftHeight) * channels.count
        let widthView = (ProgramVC.widthHour + ProgramVC.shiftHeight) * 25
        mainView.frame = CGRect(x: 0, y: 0, width: widthView, height: heightView)
        
        //fill program
        let startTime = NSCalendar.current.startOfDay(for: Date())
        let stopTime = startTime.addingTimeInterval(24*60*60)
        var y = ProgramVC.shiftHeight/2
        
        let startScaleTime = startTime.addingTimeInterval(-30*60)
        let pixelInSecond : Double = Double(widthView) / (25.0*60*60)
        
        for channel in channels {
            let programs = ProgramManager.instance.getPrograms(channel: channel.name, from:startTime, to:stopTime )
            for program in programs {
                guard let start = program.start as? Date,
                      let stop = program.stop as? Date
                else {
                    continue
                }
                
                var timeShift = start.timeIntervalSince(startScaleTime)
                if timeShift < 0 {
                    timeShift  = 0
                }
                let x = Int(Double(timeShift) * pixelInSecond)
                let timeWidth = stop.timeIntervalSince(start)
                let width = Int(Double(timeWidth) * pixelInSecond)
                let frame = CGRect(x: x, y: y, width: width, height: ProgramVC.heightElement)
                let programCell = ProgramFocusedCell(frame: frame)
                mainView.addSubview(programCell)
                
            }
            y += ProgramVC.shiftHeight + ProgramVC.heightElement
        }

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

